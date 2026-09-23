import MaskedView from '@react-native-community/masked-view'
import React from 'react'
import { Image, ImageBackground, SafeAreaView, TouchableOpacity, View } from 'react-native'
import { Grayscale } from 'react-native-color-matrix-image-filters'
import props from './props'
import styles from './styles'
import LottieView from 'lottie-react-native'
import { vh } from '../../../../helpers/dimensions'
export default ({
  item,
  onPressAction,
  imageSource,
  maskSource,
  liquidSource,
  liquidFillPercentage,
  styleTouchable,
  isCentered = false,
  isBottom = false,
  readonly = false,
}: props) => {
  const isEnabled = item.enabled === true;
  // const isEnabled = true;
  const hitboxMode = false;
  const [isPressing, setIsPressing] = React.useState(false);

  return (
    <>
      <View
        style={[styleTouchable, { backgroundColor: 'transparent' }, hitboxMode ? styles.visibleContainerZone : null]}>

        <View style={styles.centerContent}>
          <>
            <TouchableOpacity
              style={[isCentered ? styles.positionTouchableCenter : styles.positionTouchable, hitboxMode ? styles.visibleTouchableZone : null]}
              disabled={readonly}
              onPressIn={() => { setIsPressing(true) }}
              onPressOut={() => { setIsPressing(false) }}
              onLongPress={() => { setIsPressing(true) }}
              onPress={onPressAction} />
            <Grayscale amount={isEnabled ? 0 : 1}>


              <ImageBackground
                style={[
                  isPressing ? styles.lowOpacity : null,
                  isCentered ? styles.imageSizeCentered : !isBottom ? styles.imageSizeSides : styles.imageSizeBottom,
                  readonly ? styles.lowOpacity : null,
                  isCentered ? styles.imgAdjustCentered : isBottom ? styles.imgAdjustBottom : styles.imgAdjustSides]}
                source={imageSource}
                resizeMode={'cover'}
              >

                {isEnabled ?
                  <MaskedView
                    style={[isCentered ? styles.imageSizeCentered : !isBottom ? styles.imageSizeSides : styles.imageSizeBottom,]}
                    maskElement={
                      <Image
                        style={[isCentered ? styles.imageSizeCentered : !isBottom ? styles.imageSizeSides : styles.imageSizeBottom,]}
                        source={maskSource}
                        resizeMode={'cover'}
                      />
                    }
                  >
                    <LottieView
                      style={[isCentered ? styles.liquidMaskCentered : !isBottom ? styles.liquidMask : styles.liquidMaskBottom, { bottom: (liquidFillPercentage - 100) }]}
                      source={liquidSource}
                      autoPlay={true}
                      loop={true}
                    />
                  </MaskedView> : <></>}
              </ImageBackground>
            </Grayscale>
          </>
        </View>
      </View>
    </>
  )
}