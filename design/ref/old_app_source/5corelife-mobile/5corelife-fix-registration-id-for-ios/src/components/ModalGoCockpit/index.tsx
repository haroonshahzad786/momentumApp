import React, { useState, useEffect } from 'react'
import { View, ImageBackground, Image, SafeAreaView, Animated, Text, Easing, TouchableOpacity } from 'react-native'
import Modal from 'react-native-modal'
import { useRecoilState } from 'recoil'
import { storageAtom } from '../../recoil/atoms'
import ModalScreenBase from '../ModalScreenBase'
import props from './props'
import strings from './strings'
import styles from './styles'

export default function index({ onPress, isVisible, touchableOpacityContainerButtonStyle, textTitleButtonStyle }: props) {

    const [storage] = useRecoilState(storageAtom)

    const {
        value: { fonts, palette },
    } = storage

    const imageMonitor = require('../../assets/images/quests/monitor.png')
    const imageFormBack = require('../../assets/images/journey/formCont.png');

    return (
        <View style={styles.body}>
            <ModalScreenBase
                touchableOpacityContainerButtonStyle={
                    touchableOpacityContainerButtonStyle
                }
                textTitleButtonStyle={textTitleButtonStyle}
                imageMonitor={imageMonitor}
                textTitle={strings.BUTTON_OK}
                onClick={onPress}
                isVisible={isVisible}>
                <View style={[styles.viewTextScreen]}>
                    <ImageBackground
                        style={styles.imageFormBack}
                        source={imageFormBack}
                        resizeMode={'cover'}>
                        <Text
                            style={[
                                styles.titleText,
                                {
                                    color: palette.TEXT_PRIMARY,
                                },
                            ]}>
                            {strings.TITLE}
                        </Text>
                    </ImageBackground>
                    {/* <Text
                        style={[
                            fonts.MODAL_TITLE,
                            styles.textScreen,
                            { color: palette.TEXT_PRIMARY, fontSize: 30 }
                        ]}>
                        {strings.TITLE}
                    </Text> */}
                </View>
                <View style={[styles.viewTextScreenSecundary]}>
                    <Text
                        style={[
                            fonts.MODAL_SUBTITLE,
                            styles.textScreen,
                            { color: palette.TEXT_PRIMARY }
                        ]}>
                        {strings.SUBTITLE}
                    </Text>
                </View>
            </ModalScreenBase>
        </View>
    )
}
