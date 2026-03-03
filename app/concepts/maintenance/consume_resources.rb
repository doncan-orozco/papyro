# frozen_string_literal: true

module Maintenance
  class ConsumeResources < Trailblazer::Operation
    step :consume_all_resources

    CPU_THREAD_COUNT = 1
    CPU_LOOP_DURATION = 57 * 60 # seconds (57 minutes)
    CPU_SLEEP = 0.03 # seconds, throttle for ~30% usage

    MEMORY_ARRAYS = 4
    FLOATS_PER_ARRAY = 67_108_864 # ~2GB per array assuming 64-bit floats (8 bytes each)
    MEMORY_LOOP_DURATION = 57 * 60 # seconds (57 minutes)
    MEMORY_SLEEP = 5 # seconds

    NETWORK_DOMAINS = [ "https://papyro.net" ]
    NETWORK_REQUESTS_PER_DOMAIN = 10
    NETWORK_LOOP_DURATION = 57 * 60 # seconds
    NETWORK_SLEEP = 1 # seconds

    def consume_all_resources(_ctx, **)
      threads = []

      # CPU load
      threads << Thread.new do
        cpu_threads = []
        CPU_THREAD_COUNT.times do
          cpu_threads << Thread.new do
            t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            while Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0 < CPU_LOOP_DURATION
              Math.sqrt(rand)
              sleep CPU_SLEEP
            end
          end
        end
        cpu_threads.each(&:join)
      end

      # Memory load
      threads << Thread.new do
        arrs = []
        MEMORY_ARRAYS.times do
          arrs << Array.new(FLOATS_PER_ARRAY) { rand }
        end
        t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        while Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0 < MEMORY_LOOP_DURATION
          arrs.map(&:sum).sum # force usage
          sleep MEMORY_SLEEP
        end
      end

      # Network load
      threads << Thread.new do
        t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        while Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0 < NETWORK_LOOP_DURATION
          NETWORK_DOMAINS.each do |url|
            NETWORK_REQUESTS_PER_DOMAIN.times do
              Net::HTTP.get(URI(url))
            end
          end
          sleep NETWORK_SLEEP
        end
      rescue StandardError
        # Network errors are acceptable during load generation
      end

      threads.each(&:join)
      true
    end
  end
end
