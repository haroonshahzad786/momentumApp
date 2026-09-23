import React, { useRef } from 'react'
import {
  ImageBackground,
  Image,
  Dimensions,
  View,
} from 'react-native'
import Modal from 'react-native-modal'
import { getImageByOriginDestinationName } from '../../helpers/internalDataManagement'
import props from './props'
import styles from './styles'

export default ({
  isPositionActual,
  isVisible,
  action,
  // isModalVisibled,
}: props) => {
  return (
    <>
      <Modal
        isVisible={isVisible}
        animationIn={'slideInDown'}
        animationInTiming={500}
        animationOut={'slideOutUp'}
        animationOutTiming={500}
      // onModalHide={isModalVisibled}
      >
        <ImageBackground
          style={styles.imageBackgroundContainer}
          source={require('../../assets/images/shared/background_universe.png')}
          resizeMode={'cover'}>
          <Image
            style={styles.imagePlanet}
            source={getImageByOriginDestinationName(isPositionActual).image}
            resizeMode={'contain'}
          />
          {
            action === 'landing'
              ?
              <Image
                style={styles.imageRocketLanding}
                source={require('../../assets/images/shared/Rocket-ok.gif')}
                resizeMode={'contain'}
              />
              :
              <Image
                style={styles.imageRocket}
                source={require('../../assets/images/shared/leavingplanet.gif')}
                resizeMode={'contain'}
              />
          }

        </ImageBackground>
      </Modal>
    </>
  )
}
