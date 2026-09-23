import React, { useEffect, useState } from 'react';
import { View, ImageBackground, Text, Image } from 'react-native';
import props from './props';
import strings from './strings';
import styles from './styles';
import { vh, vw } from '../../helpers/dimensions'
import { logger } from '../../helpers/logger';

export default function index({
    planet,
    style,
}: props) {
    logger.info("[<ModalPlanet>]")
    const { destination, momentum_required } = planet;
    const [modalStyle, setModalStyle] = useState<object>({})
    const [destiny, setDestiny] = useState<string>('');
    const [fontSize, setFontSize] = useState<number>(0);

    useEffect(() => {
        (() => {
            switch (destination) {
                case 'Space Station 1': // Space Station 1
                    setModalStyle({
                        left: vw(18),
                        bottom: vh(14),
                    })
                    break;
                case 'The Moon': // The Moon
                    setModalStyle({
                        right: vw(22),
                        bottom: vh(26),
                    })
                    break;
                case 'Mars': // Mars
                    setModalStyle({
                        left: vw(14),
                        bottom: vh(33),
                    })
                    break;
                case 'Ceres': // Ceres
                    setModalStyle({
                        right: vw(24),
                        bottom: vh(45),
                    })
                    break;
                case 'Jupiter': // Jupiter
                    setModalStyle({
                        left: vw(14),
                        bottom: vh(62),
                    })
                    break;
                case 'Europa': // Europa
                    setModalStyle({
                        left: vw(38),
                        bottom: vh(66),
                    })
                    break;
                case 'Saturn': // Saturn
                    setModalStyle({
                        right: vw(22),
                        bottom: vh(80),
                    })
                    break;
                case 'Titan': // Titan
                    setModalStyle({
                        right: vw(41),
                        top: vh(60),
                    })
                    break;
                case 'Space Station 2': // Space Station 2
                    setModalStyle({
                        left: vw(12),
                        top: vh(52.5),
                    })
                    break;
                case 'Uranus': // Uranus
                    setModalStyle({
                        right: vw(22),
                        top: vh(42),
                    })
                    break;
                case 'Space Station 3': // Space Station 3
                    setModalStyle({
                        right: vw(34),
                        top: vh(28),
                    })
                    break;
                case 'Neptune': // Neptune
                    setModalStyle({
                        left: vw(12),
                        top: vh(26),
                    })
                    break;
                case 'Triton': // Triton
                    setModalStyle({
                        left: vw(38),
                        top: vh(19),
                    })
                    break;
                case 'Pluto': // Pluto
                    setModalStyle({
                        right: vw(23),
                        top: vh(6),
                    })
                    break;
                case 'Eris': // Eris
                    setModalStyle({
                        left: vw(14),
                        top: vh(.3),
                    })
                    break;
            }
        })()
    }, [destination])

    if (!destination || destination === 'Endless') return null;

    return (
        <>
            <ImageBackground
                source={require('../../assets/images/lifetime/dialog.png')}
                resizeMode="contain"
                style={[styles.container, modalStyle]}
            >
                <ImageBackground
                    source={require('../../assets/images/lifetime/screen.png')}
                    resizeMode="contain"
                    style={styles.childrenContainer}
                >
                    <Image
                        source={require('../../assets/images/lifetime/iconPlanet.png')}
                        resizeMode="contain"
                        style={styles.iconContainer}
                    />
                    <View>
                        <Text style={[
                            style[0], {
                                color: style[3],
                                textShadowColor: style[5],
                                textShadowOffset: { width: 0, height: 1 },
                                textShadowRadius: 1,
                            },
                            styles.textPrimary,
                            destination?.length > 8 ? { fontSize: vw(2), marginBottom: 4 } : { fontSize: vw(4) }
                        ]}>
                            {destination}
                        </Text>
                        <Text style={[
                            style[6],
                            {
                                color: style[2],
                                textShadowColor: style[4],
                                textShadowOffset: { width: 0.3, height: 1 },
                                textShadowRadius: 1,
                            },
                            styles.textSecundary
                        ]}>
                            {strings.MOMENTUM}
                        </Text>
                        <Text style={[style[0], { color: style[1] }, styles.textThird]}>
                            {momentum_required}
                        </Text>
                    </View>
                </ImageBackground>
            </ImageBackground>
        </>
    )
}
