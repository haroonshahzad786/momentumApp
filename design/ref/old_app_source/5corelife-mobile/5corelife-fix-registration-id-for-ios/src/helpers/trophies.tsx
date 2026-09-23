import { logger } from "./logger";

export default (items: Array<object | any>) => {
    /*{
        id: 1,
        name: 'Trophy Name',
        type: 'locked_trophie',
        image_trophie:        image_title: '' ,
 null,
        description: 'Text how to get this trophy consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.',
        description_blue: '',
    },*/
    const object = {
        sevenDyas: false,
        fourtyDyas: false,
        twentyOneDyas: false,
        fiftyDyas: false,
        seventyFiveDyas: false,
        oneHundredDyas: false,
        moon: false,
        mars: false,
        saturn: false,
        pluton: false,
        oneHabits: false,
        fiveHabits: false,
        tenHabits: false,
        twentyHabits: false,
    }
    let trophyUserList = [{}];
    items.length < 1 ? items = [{ name: 'undefined' }] : items;
    items.map((resp) => {
        switch (resp?.trophy?.name) {
            case '7-day Streak':
                object.sevenDyas = true;
                break;
            case '14-day Streak':
                object.fourtyDyas = true;
                break;
            case '21-day Streak':
                object.twentyOneDyas = true;
                break;
            case '50 Momentum':
                object.fiftyDyas = true;
                break;
            case '75 Momentum':
                object.seventyFiveDyas = true;
                break;
            case '100 Momentum':
                object.oneHundredDyas = true;
                break;
            case 'Moon':
                object.moon = true;
                break;
            case 'Mars':
                object.mars = true;
                break;
            case 'Saturn':
                object.saturn = true;
                break;
            case 'Pluto':
                object.pluton = true;
                break;
            case '1 Habit complete':
                object.oneHabits = true;
                break;
            case '5 Habit complete':
                object.fiveHabits = true;
                break;
            case '10 Habit complete':
                object.tenHabits = true;
                break;
            case '20 Habit complete':
                object.twentyHabits = true;
                break;
        }

        trophyUserList = [
            {
                id: 0,
                name: '7-day Streak',// resp?.name !== '7-day Streak' ? 'Trophy Name' : , // "You've unlocked this trophie!",
                type: 'streak_days_trohpie',
                image_trophie: object.sevenDyas ? require('../assets/images/trophies/trophy_default.png') : require('../assets/images/trophies/trophie_locked.png'),
                image_title: object.sevenDyas ? require('../assets/images/trophies/7DayStreak.png') : null,
                description: '7-day Streak',// "You've unlocked this trophy!",
                description_blue: 'Complete 7 Night Check-ins in a row' // '2 DAYS OF 7',
            },
            {
                id: 1,
                name: '14-day Streak', // "You've unlocked this trophie!",
                type: 'streak_days_trohpie',
                image_trophie: object.fourtyDyas ? require('../assets/images/trophies/trophy_default.png') : require('../assets/images/trophies/trophie_locked.png'),
                image_title: object.fourtyDyas ? require('../assets/images/trophies/14DayStreak.png') : null,
                description: '14-day Streak',// "You've unlocked this trophy!",
                description_blue: 'Complete 14 Night Check-ins in a row' // '2 DAYS OF 7',
            },
            {
                id: 2,
                name: "21-day Streak",
                type: 'streak_days_trohpie',
                image_trophie: object.twentyOneDyas ? require('../assets/images/trophies/trophy_default.png') : require('../assets/images/trophies/trophie_locked.png'),
                image_title: object.twentyOneDyas ? require('../assets/images/trophies/21DayStreak.png') : null,
                description: '21-day Streak', // "You've unlocked this trophy!",
                description_blue: 'Complete 21 Night Check-ins in a row' // '2 DAYS OF 14',
            },
            {
                id: 3,
                name: "50 Momentum",
                type: 'completed_trophie',
                image_trophie: object.fiftyDyas ? require('../assets/images/trophies/trophy_momentum.png') : require('../assets/images/trophies/trophie_locked.png'),
                image_title: object.fiftyDyas ? require('../assets/images/trophies/letterCompleted.png') : null,
                description: "50 Momentum",
                description_blue: 'Have 50 Momentum',
            },
            {
                id: 4,
                name: '75 Momentum',
                type: 'completed_trophie',
                image_trophie: object.seventyFiveDyas ? require('../assets/images/trophies/trophy_momentum.png') : require('../assets/images/trophies/trophie_locked.png'),
                image_title: object.seventyFiveDyas ? require('../assets/images/trophies/letterCompleted.png') : null,
                description: '75 Momentum',
                description_blue: 'Have 75 Momentum',// 'MOMENTUM',
            },
            {
                id: 5,
                name: "100 Momentum",
                type: 'completed_trophie',
                image_trophie: object.oneHundredDyas ? require('../assets/images/trophies/trophy_momentum.png') : require('../assets/images/trophies/trophie_locked.png'),
                image_title: object.oneHundredDyas ? require('../assets/images/trophies/letterCompleted.png') : null,
                description: "100 Momentum",
                description_blue: 'Have 100 Momentum',
            },
            {
                id: 6,
                name: 'Moon', // 'Trophy Name',
                type: 'reached_trophie',
                image_trophie: object.moon ? require('../assets/images/trophies/trophy_moon.png') : require('../assets/images/trophies/trophie_locked.png'),
                image_title: object.moon ? require('../assets/images/trophies/letterReached.png') : null,
                description: 'THE MOON!',
                description_blue: 'Reach the Moon',
            },
            {
                id: 7,
                name: 'Mars', // 'Trophy Name',
                type: 'reached_trophie',
                image_trophie: object.mars ? require('../assets/images/trophies/trophy_mars.png') : require('../assets/images/trophies/trophie_locked.png'),
                image_title: object.mars ? require('../assets/images/trophies/letterReached.png') : null,
                description: 'MARS!',
                description_blue: 'Reach Mars'//'10 DAYS OF 10',
            },
            {
                id: 8,
                name: "Saturn",
                type: 'reached_trophie',
                image_trophie: object.saturn ? require('../assets/images/trophies/trophy_saturn.png') : require('../assets/images/trophies/trophie_locked.png'),
                image_title: object.saturn ? require('../assets/images/trophies/letterReached.png') : null,
                description: "SATURN!",
                description_blue: 'Reach Saturn',
            },
            {
                id: 9,
                name: 'Pluto', // 'Trophy Name',
                type: 'reached_trophie',
                image_trophie: object.pluton ? require('../assets/images/trophies/trophy_pluto.png') : require('../assets/images/trophies/trophie_locked.png'),
                image_title: object.pluton ? require('../assets/images/trophies/letterReached.png') : null,
                description: 'PLUTO!',
                description_blue: 'Reach Pluto'// '20 DAYS OF 20',
            },
            {
                id: 10,
                name: '1 Habit complete',
                type: 'completed_trophie',
                image_trophie: object.oneHabits ? require('../assets/images/trophies/trophy_momentum.png') : require('../assets/images/trophies/trophie_locked.png'),
                image_title: object.oneHabits ? require('../assets/images/trophies/letterCompleted.png') : null,
                description: '1 Habit complete',
                description_blue: 'Tag 1 habit as formed in Habit Overview',
            },
            {
                id: 11,
                name: '5 Habit complete',
                type: 'completed_trophie',
                image_trophie: object.fiveHabits ? require('../assets/images/trophies/trophy_momentum.png') : require('../assets/images/trophies/trophie_locked.png'),
                image_title: object.fiveHabits ? require('../assets/images/trophies/letterReached.png') : null,
                description: '5 Habit complete',
                description_blue: 'Tag 5 habits as formed in Habit Overview',
            },
            {
                id: 12,
                name: '10 Habit complete',
                type: 'completed_trophie',
                image_trophie: object.tenHabits ? require('../assets/images/trophies/trophy_momentum.png') : require('../assets/images/trophies/trophie_locked.png'),
                image_title: object.tenHabits ? require('../assets/images/trophies/letterCompleted.png') : null,
                description: '10 Habit complete',
                description_blue: 'Tag 10 habits as formed in Habit Overview',
            },
            {
                id: 13,
                name: '20 Habit complete',
                type: 'completed_trophie',
                image_trophie: object.twentyHabits ? require('../assets/images/trophies/trophy_momentum.png') : require('../assets/images/trophies/trophie_locked.png'),
                image_title: object.twentyHabits ? require('../assets/images/trophies/letterCompleted.png') : null,
                description: '20 Habit complete',
                description_blue: 'Tag 20 habits as formed in Habit Overview',
            },
        ];
    })
    logger.info("line 204 trophies trophyUserList: ", trophyUserList.length);
    return trophyUserList;
}