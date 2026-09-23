import React from 'react'
import { Image, TouchableOpacity } from 'react-native'

import props from './props'
import styles from './styles'

export default ({ onPress }: props) => {
  return (
    <>
      <TouchableOpacity style={styles.container} onPress={onPress}>
        <Image
          style={styles.imageScreen}
          source={require('../../assets/images/cockpit_categories/screen.png')}
        />
      </TouchableOpacity>
    </>
  )
}
