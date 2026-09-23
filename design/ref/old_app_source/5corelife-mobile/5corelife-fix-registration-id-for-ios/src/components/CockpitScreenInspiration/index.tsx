import React from 'react'
import { Text, ImageBackground, View } from 'react-native'

import props from './props'
import styles from './styles'

export default ({ textTitle, textTitleStyle }: props) => {
  return (
    <>
      <View style={styles.viewContainer}>
        <ImageBackground
          style={styles.imageBackgroundScreen}
          source={require('../../assets/images/shared/screen_inspiration.png')}
          resizeMode={'contain'}>
          <View style={styles.viewTitle}>
            <Text style={[styles.textTitle, textTitleStyle]} numberOfLines={5}>
              {textTitle}
            </Text>
          </View>
        </ImageBackground>
      </View>
    </>
  )
}
