export const listQuiz = (core: string, quiz: { quiz: boolean, quiz1: boolean, quiz2: boolean }) => {
    switch (core) {
        case 'MINDSET':
            return {
                title: quiz.quiz ? 'When it comes to your fears, you see them as...' : quiz.quiz1 ? 'In general, I...' : quiz.quiz2 && "Let's say dancint isn't your thing. Which one of these statements would you be more likely to say?",
                arrayAnswer: [
                    {
                        id: "1",
                        answer: quiz.quiz ? 'Things to avoid at all cost' : quiz.quiz1 ? "Ignore issues/problems and hope they'll go away on their own" : quiz.quiz2 && "I suck at dancing and will never be good, why bother.",
                        point: 0,
                    },
                    {
                        id: "2",
                        answer: quiz.quiz ? 'I face them head-on, but maybe not the best with others' : quiz.quiz1 ? 'Know I should probably make some changes, but find it hard to start' : quiz.quiz2 && "I enjoy dancing, but I'm embarrased to do it in public.",
                        point: 1,
                    },
                    {
                        id: "3",
                        answer: quiz.quiz ? 'Opportunities to grow' : quiz.quiz1 ? "Proactively make changes to things I don't like or aren't working" : quiz.quiz2 && "I haven't acquired the skill of dancing, but could if I wanted to",
                        point: 2,
                    }
                ]
            }
        case 'EMOTIONAL_HEALTH':
            return {
                title: quiz.quiz ? "Do you remind yourself on a daily basis what you're grateful for?" : quiz.quiz1 ? "I consider myself someone who..." : quiz.quiz2 && "How often do you something generous or charitable for others (donating $1 here and there doesn't count)?",
                arrayAnswer: [
                    {
                        id: "1",
                        answer: quiz.quiz ? "No - very rarely." : quiz.quiz1 ? 'Rushes through each day, without picking my head up, and am constantly being pulled from one direction to the next.' : quiz.quiz2 && "I can't remember the last time.",
                        point: 0,
                    },
                    {
                        id: "2",
                        answer: quiz.quiz ? "Sometimes." : quiz.quiz1 ? "Enjoys life when I have time, but find my other priorities get in the way." : quiz.quiz2 && "Once every so often. I should do it more.",
                        point: 1,
                    },
                    {
                        id: "3",
                        answer: quiz.quiz ? "Yes, every day." : quiz.quiz1 ? "Stops to smell the roses because life is short and I must live each day to the fullest." : quiz.quiz2 && "Daily (it's part of my life)",
                        point: 2,
                    }
                ]
            }
        case 'RELATIONSHIPS':
            return {
                title: quiz.quiz ? "In general, I consider myself someone who is..." : quiz.quiz1 ? "I tend to..." : quiz.quiz2 && "In general, I...",
                arrayAnswer: [
                    {
                        id: "1",
                        answer: quiz.quiz ? "Led by my emotions, and often gets me into trouble" : quiz.quiz1 ? "Talk more than I listen" : quiz.quiz2 && "Wait for others to reach out to me, or use socual media to show my love.",
                        point: 0,
                    },
                    {
                        id: "2",
                        answer: quiz.quiz ? "Somewhere in between" : quiz.quiz1 ? "Not sure" : quiz.quiz2 && "Somewhere in between",
                        point: 1,
                    },
                    {
                        id: "3",
                        answer: quiz.quiz ? "In control of my emotions and aware of and respond appropiately to the emotions of others" : quiz.quiz1 ? "Listen more than I talk" : quiz.quiz2 && "Proactively keep in touch/spend time with the people I care about.",
                        point: 2,
                    }
                ]
            }
        case 'PHYSICAL_HEALTH':
            return {
                title: quiz.quiz ? "When I say exercise, your first thought is:" : quiz.quiz1 ? "Do you check what's in your food (processed, amount of sugar, salt, calories, etc)?" : quiz.quiz2 && "Do you have a method to track your health (Fitbit, exercise or food habits app, etc)?",
                arrayAnswer: [
                    {
                        id: "1",
                        answer: quiz.quiz ? "Hate it - If I see a treadmill, I would rather run away from it then get on it." : quiz.quiz1 ? "No" : quiz.quiz2 && "No",
                        point: 0,
                    },
                    {
                        id: "2",
                        answer: quiz.quiz ? "I know I should do more, but don't have enough time or find it hard to motivate myself." : quiz.quiz1 ? "Maybe/Sometimes" : quiz.quiz2 && "Maybe/Sometimes",
                        point: 1,
                    },
                    {
                        id: "3",
                        answer: quiz.quiz ? "Love it - I stay active wherever I can and have a set weekly routine.." : quiz.quiz1 ? "Yes" : quiz.quiz2 && "Yes",
                        point: 2,
                    }
                ]
            }
        case 'CAREER_FINANCES':
            return {
                title: quiz.quiz ? "If there was no possible way you could fail and you could do anything you wanted, your life..." : quiz.quiz1 ? "Every morning I..." : quiz.quiz2 && "Which describes you more?",
                arrayAnswer: [
                    {
                        id: "1",
                        answer: quiz.quiz ? "Would be unrecognizable" : quiz.quiz1 ? "Have to drag myself out of bed" : quiz.quiz2 && 'I prefer to "go with the flow" and hope life will work itself out.',
                        point: 0,
                    },
                    {
                        id: "2",
                        answer: quiz.quiz ? "Somewhere in between" : quiz.quiz1 ? "Depends on the day, but in general would rather be doing something else" : quiz.quiz2 && "Somewhere in between",
                        point: 1,
                    },
                    {
                        id: "3",
                        answer: quiz.quiz ? "Wouldn't look much different" : quiz.quiz1 ? "Can't wait to get out of bed so I can get to work doing what I love" : quiz.quiz2 && "I have written and specific goals",
                        point: 2,
                    }
                ]
            }

        default:
            return { title: '', arrayAnswer: [{ id: '1', answer: '', point: 0 }] }
    }
}

export const messageForPonit = (core: string, point: number) => {
    const descriptionMindSet = `"FIRST step is switching from a VICTIM to an OWNER mentality. Instead of "I am who I am, the chips are stacked against me and there's nothing I can do about it." it's "I have everything within me to become who I want."
        This doesn't happen overnight though, To become an OWNER requires building your PERSONAL INTEGRITY by making and keeping the commitments you know are good for you. I will help you figure out these are and give you the system to make sure you stick to them."
    `;
    const descriptionEmotinal = `Being good and doing good. Self-care to make sure you're enjoying the ride and leaving the world a better place than when you entered into it.`
    const descriptionRelationships = `Establishing and maintaining fulfilled connections and gaining allies. Developing a high EQ (emotional intelligence) so you can thrive in the three main types of relationships in your life, and ensure people want to join your team and support your goals.`
    const descriptionPhysical = `Living a long, pain-free, energized life. Understanding the factors related to your physical being that contribute to this including your exercise, eating, sleep, etc.`
    const descriptionFinances = `This core is all about making sure you love what you do every day, are making good money doing it, and growing that money exponentially.`
    const Congrats = `Congrats! You've managed to build some decent momentum in this core all by your lonesome. But before giving yourself an air high five, remember that what most people "THINK" they are doing doesn't tend to match reality.`;
    const loser = `- Don't get down on yourself, most people, if they're being honest with themselves, are right there with you.
    - you will want to prioritize this core to start building some positive momentum and get your score up.
    - Habits don't care if they're good or bad, they make up who we are just the same. If you've developed some "failure habits" in this core, let's start replacing them with "success habits"!`;
    let message = '';
    switch (core) {
        case 'MINDSET':
            if (point <= 3)
                message = loser
            if (point >= 4) message = Congrats
            return { description: descriptionMindSet, message }
        case 'EMOTIONAL_HEALTH':
            if (point <= 3)
                message = loser
            if (point >= 4) message = Congrats
            return { description: descriptionEmotinal, message }
        case 'RELATIONSHIPS':
            if (point <= 3)
                message = loser
            if (point >= 4) message = Congrats
            return { description: descriptionRelationships, message }
        case 'PHYSICAL_HEALTH':
            if (point <= 3)
                message = loser
            if (point >= 4) message = Congrats
            return { description: descriptionPhysical, message }
        case 'CAREER_FINANCES':
            if (point <= 3)
                message = loser
            if (point >= 4) message = Congrats
            return { description: descriptionFinances, message }
        default:
            return { description: '', message: '' };
    }
}

export const listQuizAllCore = [
    {
        id: 0,
        image: require('../assets/images/check_in/mindset.png'),
        title: 'MINDSET',
        description: `Getting your mind working FOR instead of against you by adjusting your attitude, perception, and confidence. Becoming what I call a “growth-owner” where you know you have everything in you to accomplish your goals and obstacles are temporary roadblocks waiting for solutions.`,
        intro: true
    },
    {
        id: 1,
        question: 'When it comes to your fears, you see them as...',
        core_name: 'MINDSET',
        answer: [
            {
                id: 1,
                answer: 'Things to avoid at all cost',
                point: 0
            },
            {
                id: 2,
                answer: 'I face them head-on, but maybe not the best with others',
                point: 1
            },
            {
                id: 3,
                answer: 'Opportunities to grow',
                point: 2
            },
        ]
    },
    {
        id: 2,
        question: 'In general, I...',
        core_name: 'MINDSET',
        answer: [
            {
                id: 4,
                answer: "Ignore issues/problems and hope they'll go away on their own",
                point: 0
            },
            {
                id: 5,
                answer: 'Know I should probably make some changes, but find it hard to start',
                point: 1
            },
            {
                id: 6,
                answer: "Proactively make changes to things I don't like or aren't working",
                point: 2
            },
        ]
    },
    {
        id: 3,
        question: "Let's say dancint isn't your thing. Which one of these statements would you be more likely to say?",
        core_name: 'MINDSET',
        answer: [
            {
                id: 7,
                answer: "I suck at dancing and will never be good, why bother.",
                point: 0
            },
            {
                id: 8,
                answer: "I enjoy dancing, but I'm embarrased to do it in public.",
                point: 1
            },
            {
                id: 9,
                answer: "I haven't acquired the skill of dancing, but could if I wanted to",
                point: 2
            },
        ]
    },
    {
        id: 90,
        image: require('../assets/images/check_in/finantial.png'),
        title: 'CAREER FINANCES',
        description: `Doing what you love and are great at, executing your purpose, and exponentially growing your wealth along the way.`,
        intro: true
    },
    {
        id: 4,
        question: "If there was no possible way you could fail and you could do anything you wanted, your life...",
        core_name: 'CAREER_FINANCES',
        answer: [
            {
                id: 10,
                answer: "Would be unrecognizable",
                point: 0
            },
            {
                id: 11,
                answer: "Somewhere in between",
                point: 1
            },
            {
                id: 12,
                answer: "Wouldn't look much different",
                point: 2
            },
        ]
    },
    {
        id: 5,
        question: "Every morning I...",
        core_name: 'CAREER_FINANCES',
        answer: [
            {
                id: 13,
                answer: "Have to drag myself out of bed",
                point: 0
            },
            {
                id: 14,
                answer: "Depends on the day, but in general would rather be doing something else",
                point: 1
            },
            {
                id: 15,
                answer: "Can't wait to get out of bed so I can get to work doing what I love",
                point: 2
            },
        ]
    },
    {
        id: 6,
        question: "Which describes you more?",
        core_name: 'CAREER_FINANCES',
        answer: [
            {
                id: 16,
                answer: 'I prefer to "go with the flow" and hope life will work itself out.',
                point: 0
            },
            {
                id: 17,
                answer: "Somewhere in between",
                point: 1
            },
            {
                id: 18,
                answer: "I have written and specific goals",
                point: 2
            },
        ]
    },
    {
        id: 91,
        image: require('../assets/images/check_in/relationships.png'),
        title: 'RELATIONSHIPS',
        description: `Creating and maintaining deep, fulfilled relationships and gaining allies to help you achieve your goals.`,
        intro: true
    },
    {
        id: 7,
        question: "In general, I consider myself someone who is...",
        core_name: 'RELATIONSHIPS',
        answer: [
            {
                id: 19,
                answer: "Led by my emotions, and often gets me into trouble",
                point: 0
            },
            {
                id: 20,
                answer: "Somewhere in between",
                point: 1
            },
            {
                id: 21,
                answer: "In control of my emotions and aware of and respond appropiately to the emotions of others",
                point: 2
            },
        ]
    },
    {
        id: 8,
        question: "I tend to...",
        core_name: 'RELATIONSHIPS',
        answer: [
            {
                id: 22,
                answer: "Talk more than I listen",
                point: 0
            },
            {
                id: 23,
                answer: "Not sure",
                point: 1
            },
            {
                id: 24,
                answer: "Listen more than I talk",
                point: 2
            },
        ]
    },
    {
        id: 9,
        question: "In general, I...",
        core_name: 'RELATIONSHIPS',
        answer: [
            {
                id: 25,
                answer: "Wait for others to reach out to me, or use socual media to show my love.",
                point: 0
            },
            {
                id: 26,
                answer: "Somewhere in between",
                point: 1
            },
            {
                id: 27,
                answer: "Proactively keep in touch/spend time with the people I care about.",
                point: 2
            },
        ]
    },
    {
        id: 93,
        image: require('../assets/images/check_in/physicalHealth.png'),
        title: 'PHYSICAL HEALTH',
        description: `Taking care of your physical body to ensure looking good, feeling good, and gaining the energy and stamina to propel you through life.`,
        intro: true
    },
    {
        id: 10,
        question: "When I say exercise, your first thought is:",
        core_name: 'PHYSICAL_HEALTH',
        answer: [
            {
                id: 28,
                answer: "Hate it - If I see a treadmill, I would rather run away from it then get on it.",
                point: 0
            },
            {
                id: 29,
                answer: "I know I should do more, but don't have enough time or find it hard to motivate myself.",
                point: 1
            },
            {
                id: 30,
                answer: "Love it - I stay active wherever I can and have a set weekly routine.",
                point: 2
            },
        ]
    },
    {
        id: 11,
        question: "Do you check what's in your food (processed, amount of sugar, salt, calories, etc)?",
        core_name: 'PHYSICAL_HEALTH',
        answer: [
            {
                id: 31,
                answer: "No",
                point: 0
            },
            {
                id: 32,
                answer: "Maybe/Sometimes",
                point: 1
            },
            {
                id: 33,
                answer: "Yes",
                point: 2
            },
        ]
    },
    {
        id: 12,
        question: "Do you have a method to track your health (Fitbit, exercise or food habits app, etc)?",
        core_name: 'PHYSICAL_HEALTH',
        answer: [
            {
                id: 34,
                answer: "No",
                point: 0
            },
            {
                id: 35,
                answer: "Maybe/Sometimes",
                point: 1
            },
            {
                id: 36,
                answer: "Yes",
                point: 2
            },
        ]
    },
    {
        id: 94,
        image: require('../assets/images/check_in/emotional.png'),
        title: 'EMOTIONAL HEALTH',
        description: `Managing stress, expressing your passions regularly, and making sure you’re continually growing. Also, making sure the world is better, not worse, for having you in it`,
        intro: true
    },
    {
        id: 13,
        question: "Do you remind yourself on a daily basis what you're grateful for?",
        core_name: 'EMOTIONAL_HEALTH',
        answer: [
            {
                id: 37,
                answer: "No - very rarely.",
                point: 0
            },
            {
                id: 38,
                answer: "Sometimes",
                point: 1
            },
            {
                id: 39,
                answer: "Yes, every day.",
                point: 2
            },
        ]
    },
    {
        id: 14,
        question: "I consider myself someone who...",
        core_name: 'EMOTIONAL_HEALTH',
        answer: [
            {
                id: 40,
                answer: "Rushes through each day, without picking my head up, and am constantly being pulled from one direction to the next.",
                point: 0
            },
            {
                id: 41,
                answer: "Enjoys life when I have time, but find my other priorities get in the way.",
                point: 1
            },
            {
                id: 42,
                answer: "Stops to smell the roses because life is short and I must live each day to the fullest.",
                point: 2
            },
        ]
    },
    {
        id: 15,
        question: "How often do you something generous or charitable for others (donating $1 here and there doesn't count)?",
        core_name: 'EMOTIONAL_HEALTH',
        answer: [
            {
                id: 43,
                answer: "I can't remember the last time.",
                point: 0
            },
            {
                id: 44,
                answer: "Once every so often. I should do it more.",
                point: 1
            },
            {
                id: 45,
                answer: "Daily (it's part of my life)",
                point: 2
            },
        ]
    },
]

export const descriptionXcore = (core: string) => {
    switch (core) {
        case 'MINDSET':
            return {
                image: require('../assets/images/check_in/mindset.png'),
                title: 'MINDSET',
                description: `Getting your mind working FOR instead of against you by adjusting your attitude, perception, and confidence. Becoming what I call a “growth-owner” where you know you have everything in you to accomplish your goals and obstacles are temporary roadblocks waiting for solutions.
                `,
            }
        case 'EMOTIONAL_HEALTH':
            return {
                image: require('../assets/images/check_in/emotional.png'),
                title: 'EMOTIONAL HEALTH',
                description: `Managing stress, expressing your passions regularly, and making sure you’re continually growing. Also, making sure the world is better, not worse, for having you in it`,
            }
        case 'RELATIONSHIPS':
            return {
                image: require('../assets/images/check_in/relationships.png'),
                title: 'RELATIONSHIPS',
                description: `Creating and maintaining deep, fulfilled relationships and gaining allies to help you achieve your goals.`,
            }
        case 'PHYSICAL_HEALTH':
            return {
                image: require('../assets/images/check_in/physicalHealth.png'),
                title: 'PHYSICAL HEALTH',
                description: `Taking care of your physical body to ensure looking good, feeling good, and gaining the energy and stamina to propel you through life.
                `,
            }
        case 'CAREER_FINANCES':
            return {
                image: require('../assets/images/check_in/finantial.png'),
                title: 'CAREER FINANCES',
                description: `Doing what you love and are great at, executing your purpose, and exponentially growing your wealth along the way.`,
            }
        default:
            return {
                image: '',
                title: '',
                description: ''
            };
    }
}

export const buildQuiz = (mindset: any, emosional: any, relation: any, physical: any, career: any) => {
    return [
        {
            core: mindset.core_name,
            points: mindset.point,
        },
        {
            core: mindset.core_name,
            points: mindset.mindset.point,
        },
        {
            core: mindset.core_name,
            points: mindset.mindset.mindset.point,
        },
        {
            core: emosional.core_name,
            points: emosional.point,
        },
        {
            core: emosional.core_name,
            points: emosional.emosional.point,
        },
        {
            core: emosional.core_name,
            points: emosional.emosional.emosional.point,
        },
        {
            core: relation.core_name,
            points: relation.point,
        },
        {
            core: relation.core_name,
            points: relation.relation.point,
        },
        {
            core: relation.core_name,
            points: relation.relation.relation.point,
        },
        {
            core: physical.core_name,
            points: physical.point,
        },
        {
            core: physical.core_name,
            points: physical.physical.point,
        },
        {
            core: physical.core_name,
            points: physical.physical.physical.point,
        },
        {
            core: career.core_name,
            points: career.point,
        },
        {
            core: career.core_name,
            points: career.career.point,
        },
        {
            core: career.core_name,
            points: career.career.career.point,
        },
    ]
}
