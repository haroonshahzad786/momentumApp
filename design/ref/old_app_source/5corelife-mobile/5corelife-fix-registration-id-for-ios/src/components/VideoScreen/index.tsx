import React, { useEffect, useState } from 'react'
import { Image, TouchableOpacity, View } from 'react-native'
import Modal from 'react-native-modal'
import { useRecoilValue, useRecoilState } from 'recoil'
import { storageAtom } from '../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import { getVideoByOriginDestinationName } from '../../helpers/internalDataManagement'

//@ts-ignore
import Video from "react-native-video";

export default ({
  isVisible,
  // isLanding = false,
  onClickOk,
  destiny,
  launchOrLanding,
  // isModalVisibled,
}: props) => {
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom);

  // const videoPath = isLanding ? require("../../assets/videos/Landing.mp4") : require("../../assets/videos/Launch.mp4");

  // setTimeout(() => {
  //   onClickOk();
  // }, 5000);

  return (
    <>
      {/*<View style={styles.bgModal}>*/}
        <Modal
          isVisible={isVisible}
          animationIn={'fadeIn'}
          animationInTiming={100}
          animationOut={'fadeOut'}
          animationOutTiming={100}
          style={styles.modalContainer}
          // onModalHide={isModalVisibled}
        >
          <Video
            source={getVideoByOriginDestinationName(destiny)[launchOrLanding]}
            style={[styles.video]}
            muted={true}
            resizeMode={'cover'}
            rate={1.0}
            ignoreSilentSwitch={"obey"}
          />

          <View style={styles.containerButtonNext}>
            <TouchableOpacity onPress={onClickOk}>
              <Image
                style={styles.buttonNext}
                source={require('../../assets/images/onboarding/button_next.png')}
                resizeMode="contain"
              />
            </TouchableOpacity>
          </View>
        </Modal>
      {/*</View>*/}
    </>
  )
}
