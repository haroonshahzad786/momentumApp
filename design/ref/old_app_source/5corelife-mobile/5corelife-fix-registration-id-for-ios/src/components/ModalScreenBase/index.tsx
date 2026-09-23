import React, { useRef } from 'react'
import { ImageBackground, View, ViewStyle, Text } from 'react-native'
import Modal from 'react-native-modal'
import { vh, vw } from '../../helpers/dimensions'
import Button from '../Button'
import ButtonBack from '../ButtonBack'

import props from './props'
import styles from './styles'

export default ({
  touchableOpacityContainerButtonStyle,
  textTitleButtonStyle,
  imageMonitor,
  imageMask,
  children,
  textTitle,
  onClick,
  onCancel,
  isVisible,
  heightOffset,
  hasVeil = true,
}: props) => {
  return (
    <>
      <Modal
        isVisible={isVisible}
        animationIn={'slideInDown'}
        animationInTiming={500}
        animationOut={'slideOutUp'}
        animationOutTiming={500}
        backdropOpacity={hasVeil ? 0.85 : 1}
      >
        <View style={styles.imageBackgroundContainer}>
          <ImageBackground
            style={styles.imageBackground}
            source={imageMonitor}
            resizeMode={'stretch'}>
            {onCancel ? (
              <View style={styles.containerButtonBack}>
                <ButtonBack
                  onPress={() => {
                    onCancel()
                  }}
                />
              </View>
            ) : null}
            <View
              style={[
                styles.mainContainer,
                { height: vh(75 + (heightOffset ?? 0)) },
              ]}>
              {children}
            </View>
          </ImageBackground>
          <View style={styles.imageMask} pointerEvents={'none'}>
            <ImageBackground
              style={styles.imageMask}
              source={imageMask}
              resizeMode={'stretch'}>
              <View
                style={[
                  styles.mainContainer,
                  { height: vh(75 + (heightOffset ?? 0)) },
                ]}>
                {/* {children} */}
              </View>
            </ImageBackground>
          </View>
        </View>
        <Button
          touchableOpacityContainerStyle={[
            styles.buttonDone,
            touchableOpacityContainerButtonStyle as ViewStyle,
            { top: vh((heightOffset ?? 0) - 4.5) },
          ]}
          textTitle={textTitle}
          textTitleStyle={textTitleButtonStyle}
          onPress={onClick}
        />
      </Modal>
    </>
  )
}
