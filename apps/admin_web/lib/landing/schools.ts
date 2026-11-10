/**
 * The schools shown on the landing page's wall. Content, not configuration: a school is added here once it uses BusIn
 * and agrees to be shown. A logo is used only once the school has approved it; until then its initials stand in.
 */
export type WallSchool = { name: string; initials: string; logo?: string };

export const WALL_SCHOOLS: WallSchool[] = [{ name: "ICT University", initials: "ICTU" }];
