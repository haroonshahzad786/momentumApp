import React from 'react'
import { Image, ImageBackground, View } from 'react-native'

import props from './props'
import styles from './styles'

export default ({ children }: props) => {
  return (
    <ImageBackground
      style={[styles.container]}
      source={require('../../assets/images/cockpit_categories/background.png')}
      resizeMode={'cover'}>
      <ImageBackground
        style={[styles.containerImageBackgroundCockpit]}
        // source={require('../../assets/images/cockpit_categories/console.png')}
        source={require('../../assets/images/cockpit_categories/bkgdCokpit.png')}
        resizeMode={'stretch'}>
        <View style={styles.containerConsoleCenter}>
          <Image
            style={styles.contolerCenter}
            resizeMode={'contain'}
            source={require('../../assets/images/cockpit_categories/Radar.gif')}
          />
        </View>
        <View style={styles.containerConsoleLeft}>
          <Image
            style={styles.contolerLeft}
            resizeMode={'contain'}
            source={require('../../assets/images/cockpit_categories/Left.gif')}
          />
        </View>
        <View style={styles.containerConsoleRight}>
          <Image
            style={styles.containerConsoleRight}
            resizeMode={'contain'}
            source={require('../../assets/images/cockpit_categories/Right.gif')}
          />
        </View>
        {children}
      </ImageBackground>
    </ImageBackground>
  )
}
