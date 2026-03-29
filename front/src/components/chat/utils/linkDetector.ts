// URL detection regex
const URL_REGEX = /https?:\/\/[^\s]+/gi;
const EMAIL_REGEX = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/gi;

export interface LinkMatch {
  text: string;
  url: string;
  type: 'url' | 'email';
  start: number;
  end: number;
}

export const detectLinks = (text: string): LinkMatch[] => {
  const matches: LinkMatch[] = [];

  // Detect URLs
  let match;
  while ((match = URL_REGEX.exec(text)) !== null) {
    matches.push({
      text: match[0],
      url: match[0],
      type: 'url',
      start: match.index,
      end: match.index + match[0].length,
    });
  }

  // Detect emails
  while ((match = EMAIL_REGEX.exec(text)) !== null) {
    // Check if this email is not already part of a URL
    const isPartOfUrl = matches.some(
      m => m.start <= match!.index && m.end >= match!.index + match![0].length
    );

    if (!isPartOfUrl) {
      matches.push({
        text: match[0],
        url: `mailto:${match[0]}`,
        type: 'email',
        start: match.index,
        end: match.index + match[0].length,
      });
    }
  }

  return matches.sort((a, b) => a.start - b.start);
};

export const hasLinks = (text: string): boolean => {
  return URL_REGEX.test(text) || EMAIL_REGEX.test(text);
};

export const renderTextWithLinks = (text: string): React.ReactNode[] => {
  const links = detectLinks(text);

  if (links.length === 0) {
    return [text];
  }

  const result: React.ReactNode[] = [];
  let lastIndex = 0;

  links.forEach((link, index) => {
    // Add text before the link
    if (link.start > lastIndex) {
      result.push(text.substring(lastIndex, link.start));
    }

    // Add the link
    result.push(
      `<a href="${link.url}" target="_blank" rel="noopener noreferrer" class="message-link">${link.text}</a>`
    );

    lastIndex = link.end;
  });

  // Add remaining text
  if (lastIndex < text.length) {
    result.push(text.substring(lastIndex));
  }

  return result;
};

export const extractDomain = (url: string): string => {
  try {
    const urlObj = new URL(url);
    return urlObj.hostname.replace('www.', '');
  } catch {
    return url;
  }
};
