import { ImageSourcePropType } from 'react-native'

export interface LocalData {
  lastMorningCheckInCompleted: null | number
  lastNightCheckInCompleted: null | number
  coreInfo: Array<CoreInfo>
  onboarding: boolean
  morningCheckInStarted: boolean
  nightCheckInStarted: boolean
  currentCheckin: null | 'morning' | 'night'
  openCheckin: boolean
  lastStart: Date | null
  secondDaysJourney: boolean
  improvements: Array<Improvement>;
}

export interface CoreInfo {
  core_power: number
  core_string: string
  enabled: boolean

  lastMorningCheckIn: null | number
  morningCheckInHabits: Array<CheckinHabits>
  lastNightCheckIn: null | number
  nightCheckInScore: null | number
  openCheckin: boolean // Show a core opened to do checking.
}

export interface CheckinHabits {
  id: number
  title: string
  isSelected: boolean
  type: string
}

export interface Core {
  user: number
  core_string:
  | 'CAREER_FINANCES'
  | 'EMOTIONAL_HEALTH'
  | 'MINDSET'
  | 'PHYSICAL_HEALTH'
  | 'RELATIONSHIPS'
  enabled: boolean
  core_power: number
  habits: HabitsTypes[]
}

export interface Mantra {
  id: number
  mantra: string
}

export interface Inspiration {
  text: string
}

export interface StressKiller {
  id: number,
  name: string,
  user: number,
  order: number,
  new: boolean
}

export interface Fear {
  id: number,
  name: string,
  category: string,
}

export interface TopPerson {
  id: number
  name: string
  user: number
  core_name: string
}

export interface Messes {
  id: number,
  name: string,
  user: number,
  order: number,
  new: boolean
}

export interface DailyRoutine {
  id: number,
  name: string,
  user: number,
  order: number,
  new: boolean
}

export interface Gratitude {
  id: number,
  name: string,
  user: number,
  order: number,
  new: boolean
}

export interface OneTime {
  id: number
  name: string
  user: number
  core_name: string
}

export interface Future {
  id: number
  name: string
  user: number
  core_name: string
}

export interface UserRetrieve {
  username: string
  first_name: string
  last_name: string
  email: string
  user_profile: UserProfile
}

export interface UserProfile {
  credits: number
  momentum: number
  night_checks_in_row: number
  last_night_check: string
  core_power_increase: number
  days_in_journey: number
  morning_check_time: string
  night_check_time: string
  pause: boolean
  user_core_cap: number
  actual_destination: string
  actual_destination_length: number
  onboarding: boolean
  quiz: boolean
  trophies: []
  missions: []
  notifications: boolean
  quests: [
    {
      success: boolean
      active: boolean
      quest_name: string
    },
  ]
  cores_active: number
  cores_available: number
  secondDaysJourney ?: boolean
}

export interface Connections {
  id: number,
  name: string,
  user: number,
  order: number,
  new: boolean
}
export interface Goals {
  id: number,
  name: string,
  score: number,
  length: number,
  completed: boolean,
}
export interface Funeral {
  id: number,
  name: string,
  user: number,
  order: number,
  new: boolean
}
export interface ItemCategory {
  id: number,
  name: string,
  category: string,
}
export interface Passion {
  id: number,
  name: string,
  user: number,
  order: number,
  new: boolean
}
export interface Strength {
  id: number,
  name: string,
  category: string,
}
export interface Weaknesses {
  id: number,
  name: string,
  user: number,
  order: number,
  new: boolean
}

export interface DailyCheck {
  id: number
  user: number
  morningcheck: boolean
  nightcheck: boolean
  score: number
  core:
  | string
  | 'CAREER_FINANCES'
  | 'EMOTIONAL_HEALTH'
  | "MINDSET', 'Mindset"
  | 'PHYSICAL_HEALTH'
  | 'RELATIONSHIPS'
  open: boolean
  habits: Array<{
    id: number
    name: string
    positive: string
    description: string
    core: string
    formed: boolean
    favorite: boolean
  }>
}

export interface UserJourney {
  origin: ImageSourcePropType,
  destiny: ImageSourcePropType,
  obstacle: ImageSourcePropType | null,
  rocket: RocketComposition,
}

export interface UserLifetime {
  journey: RocketJourney,
  rocket: RocketComposition,
}

export interface RocketJourney {
  id: number,
  destiny: string,
  origin: string,
  obstacle?: string,
  xPos: number,
  yPos: number,
  angle: string
}

export interface Improvement {
  id: number,
  name: string,
  type: string,
  cost: number,
  isActive: boolean,
}

export interface RocketComposition {
  turbines: string,
  wings: string,
  color: string,
}

export interface HabitsTypes {
  id: number,
  name: string,
  positive: boolean,
  description: string,
  core: string,
  formed: boolean,
  favorite: boolean,
  selected: boolean,
  selected_date: string
}
export interface HabitsCreatedResponse {
  name: string,
  positive: boolean,
  description: string,
  core: string,
  formed: boolean,
  favorite: boolean,
  selected: boolean,
  selected_date: string | null
}

export interface HabitsCreatedRequest {
  name: string,
  positive: boolean,
  description: string,
  core: string,
  favorite: boolean,
}

export interface Destinations {
  destination: string,
  length: number,
  momentum_required: number,
  cores: number,
  core_cap: number
}

export interface MissionsUser {
  id: number,
  active: boolean,
  success: boolean,
  user_id: number,
  mission_id: number
}

export interface CockpitList {
  id: number,
  name: string,
  description: string,
  enabled: boolean,
  category: string,
  options: [],
  items: string
}

export interface CockpitListRequest {
  name: string;
  items: string
}

export interface ImprovementBase {
  name: string,
  cost: number,
  probability_reward: number,
  destination: string,
  improvement_type: string,
  default: boolean,
  order: number,
  bonus_core_cap: number,
  core_power_multiplier: number
}

export interface Leaderboards {
  username: string,
  score: number,
  armor: string,
  destination: string
}

export interface SelfReview {
  id: number,
  date: string,
  answers: []
}

export interface Improvements {
  name: string,
  cost: number,
  probability_reward: number,
  destination: string,
  improvement_type: string,
  default: boolean,
  order: number,
  bonus_core_cap: number,
  core_power_multiplier: number
}

export interface ImprovementState {
  armor: Improvements[];
  wings: Improvements[];
  thruster: Improvements[];
}

export interface ImprovementsUser {
  improvement: ImprovementBase,
  equipped: boolean
}

export interface ImprovementUserRequest {
  name: string,
  improvement_type: string
}

export interface BonusBuyRequest {
  name: string
}

export interface BonusBuyResponse {
  active: boolean,
  bonus: Bonus,
  used: boolean,
  date_active: string
}

export interface Bonus {
  id: number,
  name: string,
  cost: number,
  description: string
}

export interface Quest {
  quest: number,
  active: boolean,
  success: boolean
}

interface DailyCheckHabits {
  score: number;
  morningcheck: boolean;
  nightcheck: boolean;
  open: boolean;
  core: string;
  created: string;
}

interface UserProfileHabits {
  credits: number;
}

interface CoreHabits {
  user: number;
  core_string: string;
  enabled: boolean;
  core_power: number;
}

interface JourneyHabits {
  status: string;
  days_in_journey: number;
  actual_destination: string;
  next_destination: string;
}

interface QuestHabits {
  name: string;
  description: string;
  active: boolean;
  success: boolean;
}

interface MissionHabits {}

interface RewardHabits {}

interface TrophyHabits {}

export interface HabitsMorninAndNightgCheckResponse {
  dailychecks: DailyCheckHabits[];
  user_profile: UserProfileHabits;
  cores: CoreHabits[];
  journey: JourneyHabits;
  quest: QuestHabits;
  mission: MissionHabits;
  reward: RewardHabits;
  trophies: TrophyHabits;
}

export interface HabitsMorninCheckRequest {
  core: string,
  habits: number[]
}

export interface HabitsNightgCheckRequest {
  core: string,
  score: number
}

export interface HabitsOverviewRequest {
    id: number;
    name: string;
    positive: boolean;
    description: string;
    core: string;
    formed: boolean;
    daysRow: string | "0";
    favorite: boolean;
}

export interface Trophy {
  id: number;
  name: string;
  quantity_days: number;
  quantity_momentum: number;
  quantity_habits: number;
  reach_destination: null | string;
}

export interface HabitsOverviewResponse {
  id: number;
  name: string;
  positive: boolean;
  description: string;
  core: string;
  formed: boolean;
  favorite: boolean;
  selected: boolean;
  selected_date: string;
  trophies: Trophy[];
}

export interface CoreValuesListForHabitsNightCheck {
  core_name: string;
  habitsList: string;
  value: number
}

export interface ForgotPasswordRequest {
  email: string;
}

export interface ForgotPasswordResponse {
  response: string
}