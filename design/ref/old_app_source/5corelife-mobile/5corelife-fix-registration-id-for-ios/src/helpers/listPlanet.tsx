export default (planet: string) => {
    switch (planet) {
        case 'Space Station 1':
            return ({
                image: require('../assets/images/journey/origins_destinations/station1.png'),
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
        case 'Space Station 2':
            return ({
                image: require('../assets/images/journey/origins_destinations/station2.png'),
            })
        case 'Uranus':
            return ({
                image: require('../assets/images/journey/origins_destinations/uranus.png'),
            })
        case 'Space Station 3':
            return ({
                image: require('../assets/images/journey/origins_destinations/station3.png'),
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
        case 'Endless':
            return ({
                image: require('../assets/images/shared/rocketCopy2.png'),
            })

        default:
            break;
    }
}
