import React from 'react'
import { Image, TouchableOpacity } from 'react-native'

import props from './props'
import styles from './styles'

export default ({ onPress, disabled, stylesCustomer }: props) => {
  return (
    <>
      <TouchableOpacity disabled={disabled} style={[styles.container, stylesCustomer]} onPress={onPress}>
        <Image
          style={styles.imageButtonBack}
          source={require('../../assets/images/cockpit_categories/button_back.png')}
          resizeMode={'contain'}
        />
      </TouchableOpacity>
    </>
  )
}
