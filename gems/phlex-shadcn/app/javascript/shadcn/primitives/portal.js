// Port of @radix-ui/react-portal: the element lives in `container` (default: body) while portaled and goes back
// to its original position on release. Known divergences: none.
/**
 * Moves an element into `container` and leaves a placeholder where it was.
 * @param {HTMLElement} el
 * @param {Element} [container=document.body]
 * @returns {() => void} release: puts the element back at its original position.
 * @example
 * const release = portal(contentEl)
 */
export function portal(el, container = document.body) {
  const placeholder = document.createComment("portal")
  el.before(placeholder)
  container.append(el)

  return function release() {
    placeholder.replaceWith(el)
  }
}
