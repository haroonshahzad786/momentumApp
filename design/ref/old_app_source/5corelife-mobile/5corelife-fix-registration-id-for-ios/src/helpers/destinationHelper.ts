import { RocketJourney } from "../typescript/main";
import { logger } from "./logger";

export const journeyList = [{

  id: 15,
  destiny: 'Eris',
  origin: 'Pluto',
  xPos: 0,
  yPos: 12,
  angle: '-85deg',
},
{
  id: 14,
  destiny: 'Pluto',
  origin: 'Triton',
  xPos: 12,
  yPos: 22,
  angle: '45deg',
},
{
  id: 13,
  destiny: 'Triton',
  origin: 'Neptune',
  xPos: -20,
  yPos: 27,
  angle: '65deg',
},
{
  id: 12,
  destiny: 'Neptune',
  origin: 'Space Station 3',
  xPos: -5,
  yPos: 36,
  angle: '-80deg',
},
{

  id: 11,
  destiny: 'Space Station 3',
  origin: 'Uranus',
  xPos: 10,
  yPos: 42,
  angle: '-25deg',
},
{
  id: 10,
  destiny: 'Uranus',
  origin: 'Space Station 2',
  xPos: -23,
  yPos: 54,
  angle: '45deg',
},
{
  id: 9,
  destiny: 'Space Station 2',
  origin: 'Titan',
  xPos: -20,
  yPos: 66,
  angle: '-65deg',
},
{

  id: 8,
  destiny: 'Titan',
  origin: 'Saturn',
  xPos: 18,
  yPos: 68,
  angle: '-55deg',
},
{
  id: 7,
  destiny: 'Saturn',
  origin: 'Europa',
  xPos: 8,
  yPos: 88,
  angle: '65deg',
},
{
  id: 6,
  destiny: 'Europa',
  origin: 'Jupiter',
  xPos: -17,
  yPos: 92,
  angle: '65deg',
},
{
  id: 5,
  destiny: 'Jupiter',
  origin: 'Ceres',
  xPos: 8,
  yPos: 105,
  angle: '-55deg',
},
{
  id: 4,
  destiny: 'Ceres',
  origin: 'Mars',
  xPos: -23,
  yPos: 120,
  angle: '45deg',
},
{
  id: 3,
  destiny: 'Mars',
  origin: 'The Moon',
  xPos: 5,
  yPos: 127,
  angle: '-65deg',

},
{
  id: 2,
  destiny: 'The Moons',
  origin: 'Space Station 1',
  xPos: -10,
  yPos: 135,
  angle: '65deg',
},
{
  id: 1,
  destiny: 'Space Station 1',
  origin: 'Earth',
  xPos: 5,
  yPos: 142,
  angle: '-65deg',
}] as RocketJourney[];

export const getJourneyByDestiny = (destiny?: string) => {
  if (!destiny)
    return getJourneyById(1);

  const result = journeyList.find((x: RocketJourney) => x.destiny === destiny);

  if (!result)
    return getJourneyById(1);

  return result;
}

export const getJourneyById = (id: number) => {
  return journeyList.find((x: RocketJourney) => x.id === id);
}

const allPositions = (/*bodyCelestial: string,*/ actual: number/*, destiny: number*/) => {
  logger.debug('line 145 destinationHelpers.allPositions ACTUAL: ',actual)
  return [{
    id: 1,
    destiny: 'Space Station 1',
    origin: 'Earth',
    // xPos: actual === 0 ? 10 : destiny - actual === Math.floor(destiny / 2) || 1 ? 0 : -13,
    xPos: actual === 0 ? 10 : -13,
    yPos: actual === 0 ? 143 : 141,
    angle: actual === 0 ? '-65deg' : '-100deg',
  },
  {
    id: 2,
    destiny: 'The Moon',
    origin: 'Space Station 1',
    xPos: actual === 0 ? -22 : actual === 1 ? -10 : 10,
    yPos: actual === 0 ? 140 : actual === 1 ? 135 : 132,
    angle: actual === 0 ? '40deg' : actual === 1 ? '65deg' : '90deg',
  },
  {
    id: 3,
    destiny: 'Mars',
    origin: 'The Moon',
    xPos: actual === 0 || actual === 1 ? 15 : actual === 2 ? 0 : -17,
    yPos: actual === 0 || actual === 1 ? 129 : actual === 2 ? 126 : 125,
    angle: actual === 0 || actual === 1 ? '-65deg' : actual === 2 ? '-70deg' : '-90deg',
  },
  {
    id: 4,
    destiny: 'Ceres',
    origin: 'Mars',
    xPos: actual === 0 || actual === 1 ? -26 : actual === 2 || actual === 3 ? -11 : 7,
    yPos: actual === 0 || actual === 1 ? 121 : actual === 2 || actual === 3 ? 114 : 112,
    angle: actual === 0 || actual === 1 ? '45deg' : actual === 2 || actual === 3 ? '70deg' : '80deg',
  },
  {
    id: 5,
    destiny: 'Jupiter',
    origin: 'Ceres',
    xPos: actual >= 0 && actual <= 2 ? 14 : actual === 3 || actual === 4 ? 1 : -14,
    yPos: actual >= 0 && actual <= 2 ? 108 : actual === 3 || actual === 4 ? 103 : 99,
    angle: actual >= 0 && actual <= 2 ? '-55deg' : actual === 3 || actual === 4 ? '-55deg' : '-75deg',
  },
  {
    id: 6,
    destiny: 'Europa',
    origin: 'Jupiter',
    xPos: actual >= 0 && actual <= 3 ? -24 : actual === 4 || actual === 5 ? -17 : -17,
    yPos: actual >= 0 && actual <= 3 ? 93 : actual === 4 || actual === 5 ? 91 : 91,
    angle: actual >= 0 && actual <= 3 ? '65deg' : actual === 4 || actual === 5 ? '75deg' : '75deg',
  },
  {
    id: 7,
    destiny: 'Saturn',
    origin: 'Europa',
    xPos: actual >= 0 && actual <= 3 ? 0 : actual >= 4 && actual <= 6 ? 8 : 15,
    yPos: actual >= 0 && actual <= 3 ? 90 : actual >= 4 && actual <= 6 ? 90 : 85,
    angle: actual >= 0 && actual <= 3 ? '75deg' : actual >= 4 && actual <= 6 ? '60deg' : '40deg',
  },
  {
    id: 8,
    destiny: 'Titan',
    origin: 'Saturn',
    xPos: actual >= 0 && actual <= 3 ? 22 : actual >= 4 && actual <= 7 ? 13 : 13,
    yPos: actual >= 0 && actual <= 3 ? 70 : actual >= 4 && actual <= 7 ? 66 : 66,
    angle: actual >= 0 && actual <= 3 ? '-50deg' : actual >= 4 && actual <= 7 ? '-75deg' : '-75deg',
  },
  {
    id: 9,
    destiny: 'Space Station 2',
    origin: 'Titan',
    xPos: actual >= 0 && actual <= 4 ? -7 : actual >= 5 && actual <= 8 ? -18 : -29,
    yPos: actual >= 0 && actual <= 4 ? 66 : actual >= 5 && actual <= 8 ? 66 : 63,
    angle: actual >= 0 && actual <= 4 ? '-85deg' : actual >= 5 && actual <= 8 ? '-75deg' : '-40deg',
  },
  {
    id: 10,
    destiny: 'Uranus',
    origin: 'Space Station 2',
    xPos: actual >= 0 && actual <= 4 ? -28 : actual >= 5 && actual <= 9 ? -14 : 7,
    yPos: actual >= 0 && actual <= 4 ? 56 : actual >= 5 && actual <= 9 ? 51 : 47,
    angle: actual >= 0 && actual <= 4 ? '45deg' : actual >= 5 && actual <= 9 ? '65deg' : '85deg',
  },
  {
    id: 11,
    destiny: 'Space Station 3',
    origin: 'Uranus',
    xPos: actual >= 0 && actual <= 4 ? 12 : actual >= 5 && actual <= 9 ? 10 : 10,
    yPos: actual >= 0 && actual <= 4 ? 45 : actual >= 5 && actual <= 9 ? 40 : 40,
    angle: actual >= 0 && actual <= 4 ? '-25deg' : actual >= 5 && actual <= 9 ? '-10deg' : '-10deg',
  },
  {
    id: 12,
    destiny: 'Neptune',
    origin: 'Space Station 3',
    xPos: actual >= 0 && actual <= 6 ? 3 : actual >= 7 && actual <= 11 ? -8 : -19,
    yPos: actual >= 0 && actual <= 6 ? 35 : actual >= 7 && actual <= 11 ? 36 : 34,
    angle: actual >= 0 && actual <= 6 ? '-95deg' : actual >= 7 && actual <= 11 ? '-86deg' : '-76deg',
  },
  {
    id: 13,
    destiny: 'Triton',
    origin: 'Neptune',
    xPos: actual >= 0 && actual <= 6 ? -27 : actual >= 7 && actual <= 12 ? -20 : -15,
    yPos: actual >= 0 && actual <= 6 ? 29 : actual >= 7 && actual <= 12 ? 27 : 25,
    angle: actual >= 0 && actual <= 6 ? '50deg' : actual >= 7 && actual <= 12 ? '65deg' : '80deg',
  },
  {
    id: 14,
    destiny: 'Pluto',
    origin: 'Triton',
    xPos: actual >= 0 && actual <= 7 ? 0 : actual >= 8 && actual <= 14 ? 15 : 20,
    yPos: actual >= 0 && actual <= 7 ? 24 : actual >= 8 && actual <= 14 ? 20 : 17,
    angle: actual >= 0 && actual <= 7 ? '75deg' : actual >= 14 && actual <= 14 ? '45deg' : '35deg',
  },
  {
    id: 15,
    destiny: 'Eris',
    origin: 'Pluto',
    xPos: (actual >= 0 && actual <= 7) ? 14 : (actual >= 8 && actual <= 15) ? -7 : -26,
    yPos: (actual >= 0 && actual <= 7) ? 12 : (actual >= 8 && actual <= 15) ? 12 : 9,
    angle: (actual >= 0 && actual <= 7) ? '-85deg' : (actual >= 8 && actual <= 15) ? '-75deg' : '-55deg',
  },
  {
    id: 16,
    destiny: 'Endless',
    origin: 'Eris',
    xPos: (actual >= 0 && actual <= 7) ? -23 : (actual >= 8 && actual <= 16) ? -26 : -30,
    yPos: (actual >= 0 && actual <= 7) ? 4 : (actual >= 8 && actual <= 16) ? 3 : 2,
    angle: (actual >= 0 && actual <= 7) ? '75deg' : (actual >= 8 && actual <= 15) ? '45deg' : '35deg',
  }]
}

export const getCurrentPosition = (perfile?: any) => {
  const { actual_destination, days_in_journey, actual_destination_length } = perfile;
  if (!actual_destination) return getJourneyById(1);
  const result = allPositions(days_in_journey).find((x: RocketJourney) => x.destiny === actual_destination);
  if (!result) return getJourneyById(1);
  return result;
}