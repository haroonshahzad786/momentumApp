import React from 'react'
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view'

import props from './props'
import styles from './styles'

export default ({ children }: props) => {
  return (
    <>
      <KeyboardAwareScrollView
        scrollEnabled={false}
        contentContainerStyle={styles.container}>
        {children}
      </KeyboardAwareScrollView>
    </>
  )
}
