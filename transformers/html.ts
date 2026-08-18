import { fromHtml } from 'hast-util-from-html'
import { toHtml } from 'hast-util-to-html'
import { defineTransformer } from '@nuxt/content'
import type { Element, Root } from 'hast'

export default defineTransformer({
  name: 'html',
  extensions: ['.html'],

  parse(file) {
    const tree = fromHtml(file.body);

    const title = findElement(tree, 'title');
    const head = findElement(tree, 'head');
    const body = findElement(tree, 'body');

    if (body) {
      const id = file.id.replace(/^papers\//, '');
      rewriteLinks(body, id);
    }

    const previous = extractNavigation(tree, 'previous-page');
    const next = extractNavigation(tree, 'next-page');

    const styles = head
      ? findElements(head, 'style')
          .map(toHtml)
          .join('')
      : '';

    return {
      id: file.id,
      title: title ? getTextContent(title) : undefined,

      previous,
      next,

      html: [
        styles,
        body?.children.map(toHtml).join('') ?? '',
      ].join(''),
    };
  },
})

function extractNavigation(
  tree: Root,
  id: string,
) {
  const container = findElementById(tree, id)

  if (!container) {
    return undefined
  }

  const link = findElement(container, 'a')

  if (!link) {
    return undefined
  }

  const href = link.properties.href

  if (typeof href !== 'string') {
    return undefined
  }

  let url = stripFragment(rewriteHref(href));
  if (url == 'index') {
    url = '';
  }

  return {
    url,
    title: getTextContent(link),
  }
}

function stripFragment(href: string): string {
  const hash = href.indexOf('#')

  return hash === -1
    ? href
    : href.slice(0, hash)
}

function findElementById(
  node: Root | Element,
  id: string,
): Element | undefined {
  for (const child of node.children) {
    if (
      child.type === 'element' &&
      child.properties.id === id
    ) {
      return child
    }

    if (child.type === 'element') {
      const result = findElementById(child, id)

      if (result) {
        return result
      }
    }
  }

  return undefined
}

function findElement(
  node: Root | Element,
  tagName: string,
): Element | undefined {
  for (const child of node.children) {
    if (
      child.type === 'element' &&
      child.tagName === tagName
    ) {
      return child
    }

    if (child.type === 'element') {
      const result = findElement(child, tagName)

      if (result) {
        return result
      }
    }
  }

  return undefined
}

function findElements(
  node: Root | Element,
  tagName: string,
): Element[] {
  const elements: Element[] = []

  for (const child of node.children) {
    if (
      child.type === 'element' &&
      child.tagName === tagName
    ) {
      elements.push(child)
    }

    if (child.type === 'element') {
      elements.push(...findElements(child, tagName))
    }
  }

  return elements
}

function getTextContent(node: Element): string {
  return node.children
    .map(child => {
      if (child.type === 'text') {
        return child.value
      }

      if (child.type === 'element') {
        return getTextContent(child)
      }

      return ''
    })
    .join('')
    .trim()
}

function rewriteLinks(node: Element, basePath: string) {
  for (const child of node.children) {
    if (
      child.type === 'element' &&
      child.tagName === 'a'
    ) {
      const href = child.properties.href

      if (typeof href === 'string') {
        child.properties.href = rewriteHref(href, basePath)
      }
    }

    if (child.type === 'element') {
      rewriteLinks(child, basePath)
    }
  }
}

function rewriteHref(href: string, basePath: string): string {
  if (
    href.startsWith('#') ||
    href.startsWith('mailto:') ||
    href.startsWith('tel:') ||
    href.startsWith('javascript:') ||
    href.startsWith('https:') ||
    href.startsWith('http:')
  ) {
    return href
  }

  const url = new URL(href, `https://example.com/${basePath}`)

  // Only rewrite relative/local URLs.
  if (url.origin !== 'https://example.com') {
    return href
  }

  return url.pathname.replace(/\.html$/i, '') + url.search + url.hash
}