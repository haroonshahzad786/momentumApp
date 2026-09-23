import { atom } from 'recoil'

import fonts from '../helpers/theme'
import palettes from '../themes/palettes.json'
import { User } from '../typescript/auth'
import { AxiosRequest } from '../typescript/axios'
import {
  Core,
  Mantra,
  StressKiller,
  TopPerson,
  Fear,
  Inspiration,
  LocalData,
  Connections,
  Funeral,
  Passion,
  Strength,
  Weaknesses,
  DailyCheck,
  Improvement,
  UserRetrieve,
  Future,
  Messes,
  DailyRoutine,
  Gratitude,
  OneTime,
  Goals,
  ImprovementsUser,
} from '../typescript/main'

import { AtomLoadable } from '../typescript/recoil'
import {
  axiosAtomEffect,
  axiosAtomEffectNoCache,
  storageEffect,
} from './effects'

const storageCoreInfoDefault = [
  {
    core_power: 0,
    core_string: 'EMOTIONAL_HEALTH',
    enabled: false,
    lastMorningCheckIn: null,
    morningCheckInHabits: [],
    lastNightCheckIn: null,
    nightCheckInScore: null,
    openCheckin: false,
  },
  {
    core_power: 0,
    core_string: 'MINDSET',
    enabled: true,
    lastMorningCheckIn: null,
    morningCheckInHabits: [],
    lastNightCheckIn: null,
    nightCheckInScore: null,
    openCheckin: false,
  },
  {
    core_power: 0,
    core_string: 'CAREER_FINANCES',
    enabled: false,
    lastMorningCheckIn: null,
    morningCheckInHabits: [],
    lastNightCheckIn: null,
    nightCheckInScore: null,
    openCheckin: false,
  },
  {
    core_power: 0,
    core_string: 'RELATIONSHIPS',
    enabled: false,
    lastMorningCheckIn: null,
    morningCheckInHabits: [],
    lastNightCheckIn: null,
    nightCheckInScore: null,
    openCheckin: false,
  },
  {
    core_power: 0,
    core_string: 'PHYSICAL_HEALTH',
    enabled: false,
    lastMorningCheckIn: null,
    morningCheckInHabits: [],
    lastNightCheckIn: null,
    nightCheckInScore: null,
    openCheckin: false,
  },
]

const storageImprovementsList = [
] as Improvement[]

export const localDataDefault = {
  lastMorningCheckInCompleted: null,
  lastNightCheckInCompleted: null,
  onboarding: false,
  coreInfo: storageCoreInfoDefault,
  morningCheckInStarted: false,
  nightCheckInStarted: false,
  currentCheckin: null,
  openCheckin: false,
  secondDaysJourney: false,
  lastStart: null,
  improvements: storageImprovementsList,
}

const storageDefault = {
  fonts: fonts,
  palette: palettes.LIGHT,
  onboarding: false,
  onboarding_pendingpost: false,
  token: '',
}

const userInfoDefault = {
  lastLogin: 0,
  showAllCores: false,
}

export const localDataAtom = atom({
  key: 'localDataAtom',
  default: {
    init: false,
    value: localDataDefault,
  } as { init: boolean; value: LocalData },
  effects_UNSTABLE: [storageEffect('localDataAtom', localDataDefault)],
})

export const storageAtom = atom({
  key: 'storageAtom',
  default: {
    init: false,
    value: storageDefault,
  },
  effects_UNSTABLE: [storageEffect('storageAtom', storageDefault)],
})

export const userInfoAtom = atom({
  key: 'userInfoAtom',
  default: {
    init: false,
    value: userInfoDefault,
  },
  effects_UNSTABLE: [storageEffect('userInfoAtom', userInfoDefault)],
})

export const userAtom = atom({
  key: 'userAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, { access_token: string; user: User }>,
  effects_UNSTABLE: [axiosAtomEffect('userAtom')],
})

export const userRetrieveAtom = atom({
  key: 'userRetrieveAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, UserRetrieve>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('userRetrieveAtom')],
})

export const coresAtom = atom({
  key: 'coresAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, Core[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('coresAtom')],
})

export const userImprovementAtom = atom({
  key: 'userImprovementAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, ImprovementsUser[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('userImprovementAtom')],
})

export const mantraAtom = atom({
  key: 'mantraAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, Mantra>,
  effects_UNSTABLE: [axiosAtomEffect('mantraAtom')],
})

export const inspirationsAtom = atom({
  key: 'inspirationsAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, Inspiration[]>,
  effects_UNSTABLE: [axiosAtomEffect('inspirationsAtom')],
})

export const streesKillerAtom = atom({
  key: 'streesKillerAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, StressKiller[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('streesKillerAtom')],
})

export const fearsAtom = atom({
  key: 'fearsAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, Fear[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('fearsAtom')],
})

export const topPeopleAtom = atom({
  key: 'topPeopleAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, TopPerson[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('topPeopleAtom')],
})

export const messesAtom = atom({
  key: 'messesAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, Messes[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('messesAtom')],
})

export const connectionsAtom = atom({
  key: 'connectionsAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, Connections[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('connectionsAtom')],
})

export const goalsAtom = atom({
  key: 'goalsAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, Goals[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('goalsAtom')],
})

export const ToDoAtom = atom({
  key: 'ToDoAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, Funeral[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('ToDoAtom')],
})

export const futureAtom = atom({
  key: 'futureAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, Future[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('futureAtom')],
})

export const weaknessesAtom = atom({
  key: 'weaknessesAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, Weaknesses[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('weaknessesAtom')],
})

export const itemCategoryAtom = atom({
  key: 'itemCategoryAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, Passion[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('itemCategoryAtom')],
})

export const passionsAtom = atom({
  key: 'passionsAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, Passion[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('passionsAtom')],
})

export const strengthsAtom = atom({
  key: 'strengthsAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, Strength[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('strengthsAtom')],
})

export const dailyRoutineAtom = atom({
  key: 'dailyRoutineAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, DailyRoutine[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('dailyRoutineAtom')],
})

export const gratitudeAtom = atom({
  key: 'gratitudeAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, Gratitude[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('gratitudeAtom')],
})

export const oneTimeAtom = atom({
  key: 'oneTimeAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, OneTime[]>,
  effects_UNSTABLE: [axiosAtomEffectNoCache('oneTimeAtom')],
})

export const dailyCheckAtom = atom({
  key: 'dailyChecksAtom',
  default: {
    init: false,
    isLoading: false,
    request: null,
    value: null,
    error: null,
  } as AtomLoadable<AxiosRequest, DailyCheck[]>,
  effects_UNSTABLE: [axiosAtomEffect('dailyChecksAtom')],
})