import React from 'react'
import { Image, TouchableOpacity } from 'react-native'

import props from './props'
import styles from './styles'

export default ({ onPress, disabled }: props) => {
  return (
    <>
      <TouchableOpacity disabled={disabled} style={styles.container} onPress={onPress}>
        <Image
          style={styles.imageButtonHelp}
          source={require('../../assets/images/cockpit_categories/butHelp_3x.png')}
          resizeMode={'contain'}
        />
      </TouchableOpacity>
    </>
  )
}
