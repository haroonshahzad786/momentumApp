import React, { useState, useEffect } from 'react'
import { View, ImageBackground, Image, SafeAreaView, Animated, Text, Easing, TouchableOpacity } from 'react-native'
import Modal from 'react-native-modal'
import { useRecoilState } from 'recoil'
import { fetchAxios } from '../../helpers/axios'
import { URL } from '../../helpers/api'
import { theAlien } from '../../helpers/internalDataManagement'
import { storageAtom } from '../../recoil/atoms'
import props from './props'
import styles from './styles'
import { Inspiration } from '../../typescript/main'
import { logger } from '../../helpers/logger'

export default function index({ navigate, okButtonImage, destination, styleAlien, onclickOnAliens }: props) {

    const [storage] = useRecoilState(storageAtom)
    logger.debug("line 16 ModalAlines.index destination: ", destination, "\nstorage: ", storage)

    const {
        value: { fonts, palette, token },
    } = storage

    const [message, setMessage] = useState<any>('')
    useEffect(() => {
        (async () => {
            let Sound = require('react-native-sound')

            const soundAirlock = new Sound(
                require('../../assets/sounds/Alien_Language_00.mp3'),
                () => {
                    soundAirlock.play((success: any) => logger.info("line 28 ModalAliens.index soundAirlock.play.success: ", success))
                }
            )
            try {
                const inspirationsRandom: Inspiration = await fetchAxios<null, Inspiration>(
                    'GET',
                    URL + 'inspirations/random/',
                    token,
                    null
                )
                logger.debug("line 38 ModalAlines.index inspirationsRandom: ", inspirationsRandom)
                setMessage(inspirationsRandom);
            } catch (error: any) {
                logger.error("Inspiration random error:", error.response);
            }
        })()
    }, [])

    const [image, setImage] = useState<any>()
    const [background, setBackground] = useState<any>()
    useEffect(() => {
        const { alien, background } = theAlien(destination)
        setImage(alien)
        setBackground(background)
    }, [destination])

    const [letters, setLetter] = useState<any>()
    const [buttom, setButtom] = useState<boolean>(false)
    useEffect(() => {
        let time = setTimeout(() => {
            setLetter(message && letters + message?.text.charAt(!letters ? 0 : letters.length <= message.text.length ? (letters.length - 1) + 1 : 0))
            setButtom((message && letters && letters.length === message.text.length) ? true : false)
        }, 60);
        if (buttom) return () => clearTimeout(time);
    }, [letters, message.text])

    const finishOnAlien = () => onclickOnAliens()

    return (
        <>
            <Modal
                isVisible={true}
                animationIn={'fadeIn'}
                animationInTiming={100}
                animationOut={'fadeOut'}
                animationOutTiming={100}
                style={styles.modalContainer}
            >
                <ImageBackground
                    style={styles.container}
                    source={background}
                    resizeMode={'cover'}
                >
                    <ImageBackground
                        style={styleAlien}
                        source={image}
                        resizeMode={'cover'}
                    />
                    <View style={[styles.viewTextScreen]}>
                        <Text
                            style={[
                                fonts.MODAL_TITLE,
                                styles.textScreen,
                                { color: palette.TEXT_PRIMARY }
                            ]}>
                            {letters}
                        </Text>
                    </View>
                    {buttom &&
                        <TouchableOpacity
                            style={styles.touchableOpacityButtonNext}
                            onPress={() => finishOnAlien()}>
                            <Image
                                style={styles.imageButtonNext}
                                source={require('../../assets/images/onboarding/button_next.png')}
                                resizeMode={'contain'}
                            />
                        </TouchableOpacity>
                    }
                </ImageBackground>
            </Modal>
        </>
    )
}
