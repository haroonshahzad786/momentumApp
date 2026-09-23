import React from 'react'
import { ActivityIndicator } from 'react-native'
import { TextInput } from 'react-native-gesture-handler'
import Modal from 'react-native-modal'
import props from './props'
import styles from './styles'

export default ({
  isVisible
}: props) => {

  return (
    <Modal
      isVisible={isVisible}
      animationIn={'slideInDown'}
      animationInTiming={500}
      animationOut={'slideOutUp'}
      animationOutTiming={500}
    >
      <ActivityIndicator size="large" color="##0000ff" />
    </Modal>
  )
}
