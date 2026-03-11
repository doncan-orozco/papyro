# frozen_string_literal: true

module Maintenance
  class ConsumeResources < Trailblazer::Operation
    step :consume_all_resources

    CPU_WORKER_PROCESSES = 4
    CPU_LOOP_DURATION = 57 * 60 # seconds (57 minutes)
    CPU_CYCLE_SECONDS = 0.1
    CPU_DUTY_CYCLE = 0.4 # ~40% per worker across 4 workers -> ~40% on 4 OCPU
    MAX_RUNTIME_SECONDS = 57 * 60

    INSTANCE_MEMORY_GB = 24
    TARGET_MEMORY_PERCENT = 40
    MEMORY_CHUNK_MB = 64
    MEMORY_CHUNK_BYTES = MEMORY_CHUNK_MB * 1024 * 1024
    TARGET_MEMORY_BYTES = ((INSTANCE_MEMORY_GB * 1024 * 1024 * 1024) * TARGET_MEMORY_PERCENT / 100.0).to_i
    MEMORY_CHUNKS = [ (TARGET_MEMORY_BYTES.to_f / MEMORY_CHUNK_BYTES).ceil, 1 ].max
    MEMORY_WORKER_PROCESSES = 1
    MEMORY_LOOP_DURATION = 57 * 60 # seconds (57 minutes)
    MEMORY_SLEEP = 5 # seconds

    NETWORK_DOMAINS = [ "https://papyro.net" ]
    NETWORK_REQUESTS_PER_DOMAIN = 10
    NETWORK_LOOP_DURATION = 57 * 60 # seconds
    NETWORK_SLEEP = 1 # seconds
    NETWORK_OPEN_TIMEOUT = 2 # seconds
    NETWORK_READ_TIMEOUT = 2 # seconds

    def consume_all_resources(ctx, **)
      threads = []
      errors = []
      errors_lock = Mutex.new
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + MAX_RUNTIME_SECONDS

      # CPU load
      threads << Thread.new do
        run_cpu_worker_processes(deadline)
      rescue StandardError => e
        errors_lock.synchronize { errors << "cpu_error: #{e.class}: #{e.message}" }
      end

      # Memory load
      threads << Thread.new do
        run_memory_worker_processes(deadline)
      rescue StandardError => e
        errors_lock.synchronize { errors << "memory_error: #{e.class}: #{e.message}" }
      end

      # Network load
      threads << Thread.new do
        run_network_load(deadline)
      rescue StandardError => e
        errors_lock.synchronize { errors << "network_error: #{e.class}: #{e.message}" }
      end

      threads.each(&:join)

      if errors.any?
        ctx[:errors] = { base: errors }
        return false
      end

      ctx[:model] = {
        cpu_worker_processes: CPU_WORKER_PROCESSES,
        target_memory_bytes: TARGET_MEMORY_BYTES,
        network_domains: NETWORK_DOMAINS
      }
      true
    rescue StandardError => e
      ctx[:errors] = { base: [ "consume_resources_failed: #{e.class}: #{e.message}" ] }
      false
    end

    private

    def run_cpu_worker_processes(deadline)
      duration = [ CPU_LOOP_DURATION, remaining_time(deadline) ].min
      return if duration <= 0

      worker_script = <<~RUBY
        duration = ARGV[0].to_f
        cycle_seconds = ARGV[1].to_f
        duty_cycle = ARGV[2].to_f
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        while Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at < duration
          cycle_started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          busy_until = cycle_started_at + (cycle_seconds * duty_cycle)

          while Process.clock_gettime(Process::CLOCK_MONOTONIC) < busy_until
            Math.sqrt(rand)
          end

          cycle_elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - cycle_started_at
          remaining_sleep = cycle_seconds - cycle_elapsed
          sleep(remaining_sleep) if remaining_sleep.positive?
        end
      RUBY

      pids = []
      raise_on_failure = true
      begin
        CPU_WORKER_PROCESSES.times do
          pids << Process.spawn(
            RbConfig.ruby,
            "-e", worker_script,
            duration.to_s,
            CPU_CYCLE_SECONDS.to_s,
            CPU_DUTY_CYCLE.to_s
          )
        end
      rescue SystemCallError
        raise_on_failure = false
        terminate_processes(pids)
        raise
      ensure
        wait_for_processes(pids, raise_on_failure: raise_on_failure)
      end
    end

    def run_memory_worker_processes(deadline)
      duration = [ MEMORY_LOOP_DURATION, remaining_time(deadline) ].min
      return if duration <= 0

      worker_script = <<~RUBY
        duration = ARGV[0].to_f
        chunks_count = ARGV[1].to_i
        chunk_bytes = ARGV[2].to_i
        sleep_seconds = ARGV[3].to_f

        chunks = Array.new(chunks_count) { Random.bytes(chunk_bytes) }
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

        while Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at < duration
          chunks.each { |chunk| chunk.setbyte(0, (chunk.getbyte(0) + 1) % 255) }
          sleep(sleep_seconds)
        end
      RUBY

      pids = []
      raise_on_failure = true
      begin
        MEMORY_WORKER_PROCESSES.times do
          pids << Process.spawn(
            RbConfig.ruby,
            "-e", worker_script,
            duration.to_s,
            MEMORY_CHUNKS.to_s,
            MEMORY_CHUNK_BYTES.to_s,
            MEMORY_SLEEP.to_s
          )
        end
      rescue SystemCallError
        raise_on_failure = false
        terminate_processes(pids)
        raise
      ensure
        wait_for_processes(pids, raise_on_failure: raise_on_failure)
      end
    end

    def run_network_load(deadline)
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      while Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0 < NETWORK_LOOP_DURATION
        break if remaining_time(deadline) <= 0

        NETWORK_DOMAINS.each do |url|
          NETWORK_REQUESTS_PER_DOMAIN.times do
            perform_http_get(url)
          rescue StandardError
            # Network instability should not abort the whole operation.
          end
        end

        sleep NETWORK_SLEEP
      end
    end

    def perform_http_get(url)
      uri = URI(url)
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: NETWORK_OPEN_TIMEOUT,
        read_timeout: NETWORK_READ_TIMEOUT
      ) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end
    end

    def terminate_processes(pids)
      pids.each do |pid|
        Process.kill("TERM", pid)
      rescue Errno::ESRCH
        # Process already exited.
      end
    end

    def wait_for_processes(pids, raise_on_failure: true)
      failed_pids = []

      pids.each do |pid|
        _waited_pid, status = Process.wait2(pid)
        failed_pids << pid unless status.success?
      rescue Errno::ECHILD
        # Process already reaped.
      end

      return unless raise_on_failure && failed_pids.any?

      raise StandardError, "cpu_workers_failed: #{failed_pids.join(',')}"
    end

    def remaining_time(deadline)
      deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
