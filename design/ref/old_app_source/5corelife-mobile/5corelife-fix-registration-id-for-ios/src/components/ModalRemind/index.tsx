import React, { useState, useEffect } from 'react'
import { View, ImageBackground, Image, SafeAreaView, Animated, Text, Easing, TouchableOpacity, ScrollView } from 'react-native'
import Modal from 'react-native-modal'
import { useRecoilState } from 'recoil'
import { storageAtom } from '../../recoil/atoms'
import ModalScreenBase from '../ModalScreenBase'
import props from './props'
import strings from './strings'
import styles from './styles'
import { logger } from '../../helpers/logger'

export default function index({
    onPress,
    isVisible,
    touchableOpacityContainerButtonStyle,
    textTitleButtonStyle,
    title,
    subTitle,
    content,
}: props) {
    logger.info("[<ModalRemind>]")
    const [storage] = useRecoilState(storageAtom)

    const {
        value: { fonts, palette },
    } = storage

    const imageMonitor = require('../../assets/images/quiz/monitor.png')
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
                isVisible={isVisible}
            >
                <View style={[styles.viewTextScreen]}>
                    <Text
                        style={[
                            styles.titleText,
                            {
                                color: palette.TEXT_PRIMARY,
                            },
                        ]}>
                        {title}
                    </Text>
                </View>
                <View style={[styles.viewTextScreenSecundary]}>
                    <Text
                        style={[
                            fonts.MODAL_SUBTITLE,
                            styles.textScreen,
                            {
                                color: palette.TEXT_PRIMARY,
                            }
                        ]}>
                        {subTitle}
                    </Text>
                </View>
                <View style={styles.containerContent}>
                    <ScrollView>
                        <View style={[styles.viewTextScreenContent]}>
                            <Text
                                style={[
                                    fonts.MODAL_SUBTITLE,
                                    styles.descriptionScreen,
                                    { color: palette.TEXT_PRIMARY }
                                ]}>
                                {content}
                            </Text>
                        </View>
                    </ScrollView>
                </View>
            </ModalScreenBase>
        </View>
    )
}
