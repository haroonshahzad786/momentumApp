import { vh, vw } from "./dimensions"
import PushNotification from "react-native-push-notification";
import PushNotificationIOS from "@react-native-community/push-notification-ios";

export const getImageByCore = (core: string) => {

  switch (core) {
    case 'MINDSET':
      return ({
        order: 1,
        formalName: 'Mindset',
        primaryColor: '#AC2912',
        avatarIcon: require('../assets/images/overview/iconMindset.png'),
        avatarTitle: require('../assets/images/habits_screen/mindset.png'),
        habitScreenBackground: require('../assets/images/habits_screen/background_red.png'),
      })

    case 'EMOTIONAL_HEALTH':
      return ({
        order: 2,
        formalName: 'Emotional Health & Giving...',
        primaryColor: '#1B51A1',
        avatarIcon: require('../assets/images/overview/iconEmotional.png'),
        avatarTitle: require('../assets/images/habits_screen/emotional.png'),
        habitScreenBackground: require('../assets/images/habits_screen/background_blue.png'),
      })

    case 'RELATIONSHIPS':
      return ({
        order: 3,
        formalName: 'Relationships',
        primaryColor: '#C8348C',
        avatarIcon: require('../assets/images/overview/iconRelationships.png'),
        avatarTitle: require('../assets/images/habits_screen/relationships.png'),
        habitScreenBackground: require('../assets/images/habits_screen/background_pink.png'),
      })

    case 'PHYSICAL_HEALTH':
      return ({
        order: 4,
        formalName: 'Physical Health',
        primaryColor: '#7D2C7D',
        avatarIcon: require('../assets/images/overview/iconPhysical.png'),
        avatarTitle: require('../assets/images/habits_screen/physical.png'),
        habitScreenBackground: require('../assets/images/habits_screen/background_purple.png'),
      })

    case 'CAREER_FINANCES':
      return ({
        order: 5,
        formalName: 'Carrer & Finances',
        primaryColor: '#6E9A30',
        avatarIcon: require('../assets/images/overview/iconPhysical_2.png'),
        avatarTitle: require('../assets/images/habits_screen/career.png'),
        habitScreenBackground: require('../assets/images/habits_screen/background_green.png'),
      })

    default:
      return ({
        order: 0,
        formalName: 'FAVORITES',
        primaryColor: '#03D1D1',
        avatarIcon: require('../assets/images/overview/butFavOn.png'),
        avatarTitle: require('../assets/images/habits_screen/mindset.png'),
        habitScreenBackground: require('../assets/images/habits_screen/background.png'),
      })
  }
}

export const getImageByOriginDestinationName = (origin_destination?: string) => {
  switch (origin_destination) {
    case 'Space Station 1':
      return ({
        image: require('../assets/images/journey/origins_destinations/station1.png'),
      })

    case 'Space Station 2':
      return ({
        image: require('../assets/images/journey/origins_destinations/station2.png'),
      })

    case 'Space Station 3':
      return ({
        image: require('../assets/images/journey/origins_destinations/station3.png'),
      })

    case 'The Moon':
      return ({
        image: require('../assets/images/journey/origins_destinations/moon.png'),
      })

    case 'Mars':
      return ({
        image: require('../assets/images/journey/origins_destinations/mars.png'),
      })

    case 'Ceres':
      return ({
        image: require('../assets/images/journey/origins_destinations/ceres.png'),
      })

    case 'Jupiter':
      return ({
        image: require('../assets/images/journey/origins_destinations/jupiter.png'),
      })

    case 'Europa':
      return ({
        image: require('../assets/images/journey/origins_destinations/europa.png'),
      })

    case 'Saturn':
      return ({
        image: require('../assets/images/journey/origins_destinations/saturn.png'),
      })

    case 'Titan':
      return ({
        image: require('../assets/images/journey/origins_destinations/titan.png'),
      })

    case 'Uranus':
      return ({
        image: require('../assets/images/journey/origins_destinations/uranus.png'),
      })

    case 'Neptune':
      return ({
        image: require('../assets/images/journey/origins_destinations/neptune.png'),
      })

    case 'Triton':
      return ({
        image: require('../assets/images/journey/origins_destinations/triton.png'),
      })

    case 'Pluto':
      return ({
        image: require('../assets/images/journey/origins_destinations/pluto.png'),
      })

    case 'Eris':
      return ({
        image: require('../assets/images/journey/origins_destinations/eris.png'),
      })

    default:
      return ({
        image: require('../assets/images/journey/origins_destinations/earth.png'),
      })
  }
}

export const getVideoByOriginDestinationName = (origin_destination?: string): any => {
  /*switch (origin_destination) {
    case 'Space Station 1':
      return ({
        landing: require('../assets/videos/Landing.mp4'),
        launch: require('../assets/videos/_Launch5.mp4'),
      })

    case 'Space Station 2':
      return ({
        landing: require('../assets/videos/Landing.mp4'),
        launch: require('../assets/videos/_Launch3.mp4'),
      })

    case 'Space Station 3':
      return ({
        landing: require('../assets/videos/Landing.mp4'),
        launch: require('../assets/videos/_Launch1.mp4'),
      })

    case 'The Moon':
      return ({
        landing: require('../assets/videos/_Landing4.mp4'),
        launch: require('../assets/videos/Launch.mp4'),
      })

    case 'Mars':
      return ({
        landing: require('../assets/videos/_Landing2.mp4'),
        launch: require('../assets/videos/_Launch4.mp4'),
      })

    case 'Ceres':
      return ({
        landing: require('../assets/videos/_Landing1.mp4'),
        launch: require('../assets/videos/_Launch2.mp4'),
      })

    case 'Jupiter':
      return ({
        landing: require('../assets/videos/_Landing3.mp4'),
        launch: require('../assets/videos/_Launch1.mp4'),
      })

    case 'Europa':
      return ({
        landing: require('../assets/videos/_Landing4.mp4'),
        launch: require('../assets/videos/_Launch3.mp4'),
      })

    case 'Saturn':
      return ({
        landing: require('../assets/videos/_Landing2.mp4'),
        launch: require('../assets/videos/_Launch4.mp4'),
      })

    case 'Titan':
      return ({
        landing: require('../assets/videos/_Landing3.mp4'),
        launch: require('../assets/videos/_Launch2.mp4'),
      })

    case 'Uranus':
      return ({
        landing: require('../assets/videos/_Landing1.mp4'),
        launch: require('../assets/videos/Launch.mp4'),
      })

    case 'Neptune':
      return ({
        landing: require('../assets/videos/_Landing1.mp4'),
        launch: require('../assets/videos/Launch.mp4'),
      })

    case 'Triton':
      return ({
        landing: require('../assets/videos/_Landing4.mp4'),
        launch: require('../assets/videos/_Launch1.mp4'),
      })

    case 'Pluto':
      return ({
        landing: require('../assets/videos/_Landing1.mp4'),
        launch: require('../assets/videos/_Launch4.mp4'),
      })

    case 'Eris':
      return ({
        landing: require('../assets/videos/_Landing1.mp4'),
        launch: require('../assets/videos/_Launch1.mp4'),
      })

    default:
      return ({
        launch: require('../assets/videos/_Launch1.mp4'),
        landing: require('../assets/videos/_Launch1.mp4'),
      })
  }*/
  switch (origin_destination) {
    case 'Space Station 1':
      return ({
        landing: require('../assets/videos/copy_video/Landing_copy.mp4'),
        launch: require('../assets/videos/copy_video/_Launch5_copy.mp4'),
      })

    case 'Space Station 2':
      return ({
        landing: require('../assets/videos/copy_video/Landing_copy.mp4'),
        launch: require('../assets/videos/copy_video/_Launch3_copy.mp4'),
      })

    case 'Space Station 3':
      return ({
        landing: require('../assets/videos/copy_video/Landing_copy.mp4'),
        launch: require('../assets/videos/copy_video/_Launch1_copy.mp4'),
      })

    case 'The Moon':
      return ({
        landing: require('../assets/videos/copy_video/_Landing4_copy.mp4'),
        launch: require('../assets/videos/copy_video/Launch_copy.mp4'),
      })

    case 'Mars':
      return ({
        landing: require('../assets/videos/copy_video/_Landing2_copy.mp4'),
        launch: require('../assets/videos/copy_video/_Launch4_copy.mp4'),
      })

    case 'Ceres':
      return ({
        landing: require('../assets/videos/copy_video/_Landing1_copy.mp4'),
        launch: require('../assets/videos/copy_video/_Launch2_copy.mp4'),
      })

    case 'Jupiter':
      return ({
        landing: require('../assets/videos/copy_video/_Landing3_copy.mp4'),
        launch: require('../assets/videos/copy_video/_Launch1_copy.mp4'),
      })

    case 'Europa':
      return ({
        landing: require('../assets/videos/copy_video/_Landing4_copy.mp4'),
        launch: require('../assets/videos/copy_video/_Launch3_copy.mp4'),
      })

    case 'Saturn':
      return ({
        landing: require('../assets/videos/copy_video/_Landing2_copy.mp4'),
        launch: require('../assets/videos/copy_video/_Launch4_copy.mp4'),
      })

    case 'Titan':
      return ({
        landing: require('../assets/videos/copy_video/_Landing3_copy.mp4'),
        launch: require('../assets/videos/copy_video/_Launch2_copy.mp4'),
      })

    case 'Uranus':
      return ({
        landing: require('../assets/videos/copy_video/_Landing1_copy.mp4'),
        launch: require('../assets/videos/copy_video/Launch_copy.mp4'),
      })

    case 'Neptune':
      return ({
        landing: require('../assets/videos/copy_video/_Landing1_copy.mp4'),
        launch: require('../assets/videos/copy_video/Launch_copy.mp4'),
      })

    case 'Triton':
      return ({
        landing: require('../assets/videos/copy_video/_Landing4_copy.mp4'),
        launch: require('../assets/videos/copy_video/_Launch1_copy.mp4'),
      })

    case 'Pluto':
      return ({
        landing: require('../assets/videos/copy_video/_Landing1_copy.mp4'),
        launch: require('../assets/videos/copy_video/_Launch4_copy.mp4'),
      })

    case 'Eris':
      return ({
        landing: require('../assets/videos/copy_video/_Landing1_copy.mp4'),
        launch: require('../assets/videos/copy_video/_Launch1_copy.mp4'),
      })

    default:
      return ({
        launch: require('../assets/videos/copy_video/_Launch1_copy.mp4'),
        landing: require('../assets/videos/copy_video/_Launch1_copy.mp4'),
      })
  }
}

export const getAssetByObstacle = (obstacle: string) => {
  switch (obstacle) {
    case 'comfort_zone':
      return ({
        image: require('../assets/images/journey/obstacles/Asteroids.gif'),
      })
    case 'previous_day':
      return ({
        image: require('../assets/images/journey/obstacles/Asteroids.gif'),
      })
    case 'balanced_cores':
      return ({
        image: require('../assets/images/journey/obstacles/UFOs.gif'),
      })
    case 'core_lower':
      return ({
        image: require('../assets/images/journey/obstacles/UFOs.gif'),
      })

    default:
      return ({
        image: null,
      })
  }
}

// This function is temporal, because we don't have endpoint in backend to get the obstacle
// by mission_id
export const getObstacleByMissionId = (missionId: number) => {
  switch (missionId) {
    case 1:
      return "comfort_zone"
    case 2:
      return "balanced_cores"
    case 3:
      return "previous_day"
    case 4:
      return "core_lower"
  
    default:
      return ""
  }
}

export const getAssetByObstacleMissions = (obstacle: string) => {
  switch (obstacle) {
    case 'Go outside of comfort zone!':
      return ({
        image: require('../assets/images/journey/obstacles/asteroidsStatic.png'),
        style: {
          width: vw(70),
          height: vh(20),
        }
      })
    case 'Don’t let any core reduce its power from your previous check-in':
      return ({
        image: require('../assets/images/journey/obstacles/asteroidsStatic.png'),
        style: {
          width: vw(70),
          height: vh(20),
        }
      })
    case 'Maintain balanced cores during the day (Active cores within 40% of each other on night check-in)':
      return ({
        image: require('../assets/images/journey/obstacles/ufo.png'),
        style: {
          width: vw(70),
          height: vh(20),
        }
      })
    case 'Don’t score any core lower than 3':
      return ({
        image: require('../assets/images/journey/obstacles/ufo.png'),
        style: {
          width: vw(70),
          height: vh(20),
        }
      })
    default:
      return ({
        image: null,
      })
  }
}

export const getImprovementsColors2 = (colorType: string, forDashboard: boolean) => {
  switch (colorType) {
    case 'rocket5':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_colors/colors_rocket_dashboard/default.png'),
          color: '#1f6fd1',
          // It'll be good put on two tones colors to give 3D effect.
        })
      return ({
        image: require('../assets/images/improvement_colors/colors_rocket/rocket5.png'),
        color: '#1f6fd1',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_colors/rocket5.png'),
        shadowButton: require('../assets/images/improvement_colors/rocket_shadow.png'),
      })

    case 'rocket25':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_colors/colors_rocket_dashboard/default.png'),
          color: '#40b4b8',
        })
      return ({
        image: require('../assets/images/improvement_colors/colors_rocket/rocket25.png'),
        color: '#40b4b8',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_colors/rocket25.png'),
        shadowButton: require('../assets/images/improvement_colors/rocket_shadow.png'),
      })

    case 'rocket50':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_colors/colors_rocket_dashboard/default.png'),
          color: '#807e06',
        })
      return ({
        image: require('../assets/images/improvement_colors/colors_rocket/rocket50.png'),
        color: '#807e06',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_colors/rocket50.png'),
        shadowButton: require('../assets/images/improvement_colors/rocket_shadow.png'),
      })

    case 'rocket100':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_colors/colors_rocket_dashboard/default.png'),
          color: '#527cae',
        })
      return ({
        image: require('../assets/images/improvement_colors/colors_rocket/rocket100.png'),
        color: '#527cae',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_colors/rocket100.png'),
        shadowButton: require('../assets/images/improvement_colors/rocket_shadow.png'),
      })

    case 'rocket1000':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_colors/colors_rocket_dashboard/default.png'),
          color: '#527cae',
        })
      return ({
        image: require('../assets/images/improvement_colors/colors_rocket/rocket1000.png'),
        color: '#527cae',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_colors/rocket1000.png'),
        shadowButton: require('../assets/images/improvement_colors/rocket_shadow.png'),
      })

    default:
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_colors/colors_rocket_dashboard/default.png'),
          color: '#ec1b1b',
        })
      return ({
        image: require('../assets/images/improvement_colors/colors_rocket/default.png'),
        color: '#ec1b1b',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_colors/rocket1000.png'),
        shadowButton: require('../assets/images/improvement_colors/rocket_shadow.png'),
      })
  }
}

/**
 * @autor Miguelangel Molero
 * @param colorType @string
 * @param forDashboard @boolean
 * @description Asset Colors Rocket
 * @returns @Array
 */
export const getImprovementsColors = (colorType: string, forDashboard: boolean) => {
  switch (colorType) {
    case 'Common': // 'rocket5':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_colors/colors_rocket_dashboard/default.png'),
          color: '#ec1b1b', // '#1f6fd1',
          // It'll be good put on two tones colors to give 3D effect.
        })
      return ({
        image: require('../assets/images/improvement_colors/colors_rocket/01-rocket-armor.png'),
        color: '#ec1b1b', // '#1f6fd1',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_colors/colors_rocket/01-rocket-armor.png'),
        shadowButton: require('../assets/images/improvement_colors/rocket_shadow.png'),
        wings: require('../assets/images/improvement_wings/wings_rocket/default.png'),
      })

    case 'Uncommon': // 'rocket25':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_colors/colors_rocket_dashboard/default.png'),
          color: '#ec1b1b', // '#40b4b8',
        })
      return ({
        image: require('../assets/images/improvement_colors/colors_rocket/02-rocket-armor.png'),
        color: '#ec1b1b', //'#40b4b8',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_colors/colors_rocket/02-rocket-armor.png'),
        shadowButton: require('../assets/images/improvement_colors/rocket_shadow.png'),
        wings: require('../assets/images/improvement_wings/wings_rocket/default.png'),
      })

    case 'Rare': // 'rocket50':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_colors/colors_rocket_dashboard/default.png'),
          color: '#ec1b1b',// '#807e06',
        })
      return ({
        image: require('../assets/images/improvement_colors/colors_rocket/03-rocket-armor.png'),
        color: '#ec1b1b', // '#807e06',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_colors/colors_rocket/03-rocket-armor.png'),
        shadowButton: require('../assets/images/improvement_colors/rocket_shadow.png'),
        wings: require('../assets/images/improvement_wings/wings_rocket/default.png'),
      })

    case 'Very Rare': // 'rocket100':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_colors/colors_rocket_dashboard/default.png'),
          color: '#ec1b1b',// '#527cae',
        })
      return ({
        image: require('../assets/images/improvement_colors/colors_rocket/04-rocket-armor.png'),
        color: '#ec1b1b',// '#527cae',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_colors/colors_rocket/04-rocket-armor.png'),
        shadowButton: require('../assets/images/improvement_colors/rocket_shadow.png'),
        wings: require('../assets/images/improvement_wings/wings_rocket/default.png'),
      })

    case 'Epic': // 'rocket1000':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_colors/colors_rocket_dashboard/default.png'),
          color: '#ec1b1b',// '#527cae',
        })
      return ({
        image: require('../assets/images/improvement_colors/colors_rocket/05-rocket-armor.png'),
        color: '#ec1b1b',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_colors/colors_rocket/05-rocket-armor.png'),
        shadowButton: require('../assets/images/improvement_colors/rocket_shadow.png'),
        wings: require('../assets/images/improvement_wings/wings_rocket/default.png'),
      })

    default:
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_colors/colors_rocket_dashboard/default.png'),
          color: '#ec1b1b',
          type: 'default',
        })
      return ({
        image: require('../assets/images/improvement_colors/colors_rocket/default.png'),
        color: '#ec1b1b',
        type: 'default',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_colors/colors_rocket/default.png'),
        shadowButton: require('../assets/images/improvement_colors/rocket_shadow.png'),
        wings: require('../assets/images/improvement_wings/wings_rocket/rocket50.png'),
      })
  }
}

export const getImprovementsWings = (wingsType: string, forDashboard: boolean) => {
  switch (wingsType) {
    case 'Common': // 'rocket5':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_wings/wings_rocket_dashboard/rocket5.png'),
          color: '#1f6fd1',
        })
      return ({
        image: require('../assets/images/improvement_wings/wings_rocket/rocket5.png'),
        color: '#1f6fd1',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_wings/rocket5.png'),
      })

    case 'Uncommon': // 'rocket25':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_wings/wings_rocket_dashboard/rocket25.png'),
          color: '#40b4b8',
        })
      return ({
        image: require('../assets/images/improvement_wings/wings_rocket/rocket25.png'),
        color: '#40b4b8',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_wings/rocket25.png'),
      })

    case 'Rare': // 'rocket50':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_wings/wings_rocket_dashboard/rocket50.png'),
          color: '#807e06',
        })
      return ({
        image: require('../assets/images/improvement_wings/wings_rocket/rocket50.png'),
        color: '#807e06',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_wings/rocket50.png'),
      })

    case 'Very Rare': // 'rocket100':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_wings/wings_rocket_dashboard/rocket100.png'),
          color: '#527cae',
        })
      return ({
        image: require('../assets/images/improvement_wings/wings_rocket/rocket100.png'),
        color: '#527cae',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_wings/rocket100.png'),
      })

    case 'Epic': // 'rocket1000':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_wings/wings_rocket_dashboard/rocket1000.png'),
          color: '#527cae',
        })
      return ({
        image: require('../assets/images/improvement_wings/wings_rocket/rocket1000.png'),
        color: '#527cae',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_wings/rocket1000.png'),
      })

    default:
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_wings/wings_rocket_dashboard/default.png'),
        })
      return ({
        image: require('../assets/images/improvement_wings/wings_rocket/rocket5.png'),
        color: '#1f6fd1',
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_wings/rocket5.png'),
      })
  }
}

export const getImprovementsTurbines = (turbineType: string, forDashboard: boolean) => {

  switch (turbineType) {

    case 'Rare': // 'rocket5':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_turbines/turbines_rocket_dashboard/rocket5.png'),
          flames: 2,
        })
      return ({
        image: require('../assets/images/improvement_turbines/turbines_rocket/rocket5.png'),
        flames: 2,
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_turbines/itemRare.png'),
      })

    case 'Very Rare': // 'rocket25':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_turbines/turbines_rocket_dashboard/rocket25.png'),
          flames: 3,
        })
      return ({
        image: require('../assets/images/improvement_turbines/turbines_rocket/rocket25.png'),
        flames: 3,
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_turbines/itemVeryRare.png'),
      })

    case 'Epic': // 'rocket50':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_turbines/turbines_rocket_dashboard/rocket50.png'),
          flames: 5,
        })
      return ({
        image: require('../assets/images/improvement_turbines/turbines_rocket/rocket50.png'),
        flames: 5,
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_turbines/itemEpic.png'),
      })

    case 'Star Jump Engine': // 'rocket50':
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_turbines/turbines_rocket_dashboard/rocket50.png'),
          flames: 5,
        })
      return ({
        image: require('../assets/images/improvement_turbines/turbines_rocket/rocket50.png'),
        flames: 5,
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_turbines/itemEpic.png'),
      })

    default:
      if (forDashboard)
        return ({
          image: require('../assets/images/improvement_turbines/turbines_rocket_dashboard/default.png'),
          flames: 1,
        })
      return ({
        image: require('../assets/images/improvement_turbines/turbines_rocket/default.png'),
        flames: 1,
        titleButton: require('../assets/images/improvements/name.png'),
        iconButton: require('../assets/images/improvement_turbines/itemRare.png'),
      })
  }
}

export const getPowerFlameAnimation = (flameLevel: number) => {
  switch (flameLevel) {
    case 3:
      return ({
        image: require('../assets/animations/rocket_fire/FireHi.json'),
      })

    case 2:
      return ({
        image: require('../assets/animations/rocket_fire/FireMi.json'),
      })

    default:
      return ({
        image: require('../assets/animations/rocket_fire/FireLo.json'),
      })
  }
}

export const getLoaderAnimation = () => {
  return ({
    image: require('../assets/animations/loading/loader/Loader.json'),
  })
}

/**
 * @autor Miguelangel Molero
 * @param destination @string
 * @description Alien images before check-night
 * @returns @Array
 */
export const theAlien = (destination: string) => {
  switch (destination) {
    case 'Space Station 1':
      return ({
        alien: require('../assets/images/aliens/01-alien.png'),
        background: require('../assets/images/shared/background_universe.png')
      })

    case 'Space Station 2':
      return ({
        alien: require('../assets/images/aliens/01-alien.png'),
        background: require('../assets/images/shared/background_universe.png')
      })

    case 'Space Station 3':
      return ({
        alien: require('../assets/images/aliens/02-alien.png'),
        background: require('../assets/images/shared/background_universe.png')
      })

    case 'The Moon':
      return ({
        alien: require('../assets/images/aliens/04-alien.png'),
        background: require('../assets/images/aliens/04-alien-fondo.jpg'),
      })

    case 'Mars':
      return ({
        alien: require('../assets/images/aliens/02-alien.png'),
        background: require('../assets/images/aliens/02-alien-fondo.jpg'),
      })

    case 'Ceres':
      return ({
        alien: require('../assets/images/aliens/01-alien.png'),
        background: require('../assets/images/aliens/01-alien-fondo.jpg'),
      })

    case 'Jupiter':
      return ({
        alien: require('../assets/images/aliens/03-alien.png'),
        background: require('../assets/images/aliens/03-alien-fondo.jpg'),
      })

    case 'Europa':
      return ({
        alien: require('../assets/images/aliens/04-alien.png'),
        background: require('../assets/images/aliens/04-alien-fondo.jpg'),
      })

    case 'Saturn':
      return ({
        alien: require('../assets/images/aliens/02-alien.png'),
        background: require('../assets/images/aliens/02-alien-fondo.jpg'),
      })

    case 'Titan':
      return ({
        alien: require('../assets/images/aliens/03-alien.png'),
        background: require('../assets/images/aliens/03-alien-fondo.jpg'),
      })

    case 'Uranus':
      return ({
        alien: require('../assets/images/aliens/01-alien.png'),
        background: require('../assets/images/aliens/01-alien-fondo.jpg'),
      })

    case 'Neptune':
      return ({
        alien: require('../assets/images/aliens/01-alien.png'),
        background: require('../assets/images/aliens/02-alien-fondo.jpg'),
      })

    case 'Triton':
      return ({
        alien: require('../assets/images/aliens/04-alien.png'),
        background: require('../assets/images/aliens/04-alien-fondo.jpg'),
      })

    case 'Pluto':
      return ({
        alien: require('../assets/images/aliens/01-alien.png'),
        background: require('../assets/images/aliens/01-alien-fondo.jpg'),
      })

    case 'Eris':
      return ({
        alien: require('../assets/images/aliens/01-alien.png'),
        background: require('../assets/images/aliens/02-alien-fondo.jpg'),
      })

    default:
      return ({
        alien: require('../assets/images/aliens/01-alien.png'),
        background: require('../assets/images/shared/background_universe.png'),
      })
  }
}


/**
 * @autor Miguelangel Molero
 * @param data @string
 * @description Alien images before check-night
 * @returns @Array
*/
export const returnListWithRoute = (data: string) => {
  switch (data) {
    case 'Stress/Dwelling Killer':
      return { name: 'StressKiller', mantra: false }
    case 'Mantra':
      return { name: 'Mantra', mantra: true }
    case 'Top 5 Fears To Tackle':
      return { name: 'Fears', mantra: false }
    case 'Top People In My Life':
      return { name: 'TopPeople', mantra: false }
    case 'Initial Habit List':
      return { name: 'InitialHabitList', mantra: false }
    case 'Messes To Clean':
      return { name: 'Messes', mantra: false }
    case 'Connections':
      return { name: 'Connections', mantra: false }
    case "Bold To-do's":
      return { name: 'ToDo', mantra: false }
    case 'Passions':
      return { name: 'Passions', mantra: false }
    case 'Strengths / Weaknesses':
      return { name: 'Strengths', mantra: false }
    case 'Daily Routine':
      return { name: 'DailyRoutine', mantra: false }
    case 'Gratitude List':
      return { name: 'Gratitude', mantra: false }
    case 'One-Time-Actions':
      return { name: 'OneTime', mantra: false }
    case 'Back to the future':
      return { name: 'Future', mantra: false }
    case 'Goals':
      return { name: 'Goals', mantra: false }
    default:
      return { name: '', mantra: false };
  }
}

/**
 * @autor Miguelangel Molero
 * @param actual_destiny_cache @number
 * @param actual_destiny @number
 * @description if armor is actived
 * @returns @Array
*/
export const activedImprovementArmor = (actual_destiny_cache: any, actual_destiny: any) => {
  if (!actual_destiny) return false
  if (actual_destiny_cache >= actual_destiny) return false
  if (actual_destiny && actual_destiny_cache < actual_destiny) return true
  return true
}

/**
 * @autor Miguelangel Molero
 * @param cost_cache @number
 * @param cost @number
 * @description if wings is actived
 * @returns @Array
*/
export const activedImprovementWingsOrThruster = (cost_cache: any, cost: any) => {
  if (!parseInt(cost)) return false
  if (parseInt(cost_cache) >= parseInt(cost)) return false
  else return true
}

export const filterXcores = (core: string, a: any, data: any) => {
  let filterPhysicalHealth = Array.isArray(data) && data?.filter((response: any) => response.core_name === 'PHYSICAL HEALTH')
  let filterMindSet = Array.isArray(data) && data?.filter((response: any) => response.core_name === 'MINDSET')
  let filterCareerFinances = Array.isArray(data) && data?.filter((response: any) => response.core_name === 'CAREER FINANCES')
  let filterRelationships = Array.isArray(data) && data?.filter((response: any) => response.core_name === 'RELATIONSHIPS')
  let filterEmotionalHealt = Array.isArray(data) && data?.filter((response: any) => response.core_name === 'EMOTIONAL HEALTH')
  switch (core) {
    case 'PHYSICAL HEALTH':
      return filterPhysicalHealth;
    case 'MINDSET':
      return filterMindSet;
    case 'CAREER FINANCES':
      return filterCareerFinances;
    case 'RELATIONSHIPS':
      return filterRelationships;
    case 'EMOTIONAL HEALTH':
      return filterEmotionalHealt;
    default:
      return data
  }
}

/**
 * @autor Miguelangel Molero Pacheco
 * @param notification @object
 * @description show push-notification
*/
export const ShowNotification = (notification: any) => {
  PushNotification.localNotification({
    channelId: 'com.momentum',
    title: notification.title,
    message: notification.message,
    vibration: notification.vibration
  })
}

/**
 * @autor Miguelangel Molero Pacheco
 * @param notification @object
 * @description show push-notification/ios
*/
export const ShowNotificationIOS = (notification: any) => {
  PushNotificationIOS.addNotificationRequest({
    id: 'com.momentum',
    title: notification.title,
    body: notification.message ?? notification.body,
    
  })
}

/**
 * @autor Miguelangel Molero Pacheco
 * @param notification @object
 * @description show push-notification
*/
export const HandleScheduleNotification = (notification: any) => {
  PushNotification.localNotificationSchedule({
    channelId: 'com.momentum',
    title: notification.title,
    message: notification.message,
    date: new Date(Date.now() + 5 * 1000)
  })
}

/**
 * @autor Miguelangel Molero Pacheco
 * @param notification @object
 * @description show push-notification/ios
*/
export const HandleScheduleNotificationIOS = (notification: any) => {
  const date = new Date()
  date.setSeconds(date.getSeconds() + 5)
  PushNotificationIOS.addNotificationRequest({
    id: 'com.momentum',
    title: notification.title,
    body: notification.message,
    fireDate: date
  })
}