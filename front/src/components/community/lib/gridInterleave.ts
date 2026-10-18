/**
 * What goes between the members in the community grid: a periodic ad.
 *
 * The highlighted-profiles carousel used to interleave here too, after the
 * sixth member -- the first row boundary shared by the grid's three, two and
 * one column layouts -- with the ad yielding its row to it. That put the
 * page's showcase halfway down the list, and it was reported from production
 * as "highlighted profiles came to the middle". The carousel now renders
 * above the grid, so this decides the ad alone.
 *
 * A pure function, so the rule is testable without rendering a grid whose ad
 * component deliberately returns null until AdSense is configured.
 */

export interface InterleaveContext {
  /** How many members are in the list. */
  total: number;
}

/** Every sixth member, which is where the ad goes. */
const AD_EVERY = 6;

/**
 * Whether an ad sits directly after the member at this index. Never after the
 * last member -- an ad at the foot of the list is the sentinel's job, not the
 * grid's.
 */
export function showsAdAfter(index: number, ctx: InterleaveContext): boolean {
  if ((index + 1) % AD_EVERY !== 0) return false;
  return index !== ctx.total - 1;
}
