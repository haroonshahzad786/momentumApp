import React from 'react'
import { Image, ImageBackground, SafeAreaView, View } from 'react-native'
import styles from './styles'
import props from './props'
import strings from './strings'
import { getPowerFlameAnimation, getImprovementsColors, getImprovementsTurbines, getImprovementsWings } from '../../helpers/internalDataManagement'
import { DuoTone } from 'react-native-color-matrix-image-filters'
import LottieView from 'lottie-react-native'
import { typeFlame } from '../../helpers/flame'

export default (
  { externalStyle,
    turbines,
    skinColor,
    wings,
    flamePower = 3,
  }: props) => {
  const wingsAssetObject = getImprovementsWings(wings ?? 'default', false).image;
  const rocketAssetObject = getImprovementsColors(skinColor ?? 'default', false);
  const turbineAssetObject = getImprovementsTurbines(turbines ?? 'default', false);
  const flameAnimation = getPowerFlameAnimation(flamePower).image;

  return (
    <>
      <View style={externalStyle}>
        <DuoTone
          firstColor={/**'#ec1b1b'*/ rocketAssetObject.color }
          secondColor={/**'#ec1b1b'*/ rocketAssetObject.color }
          style={[styles.imageRocket, styles.layerRocket, styles.wings]}>
          <Image
            style={[styles.imageRocket]}
            source={wingsAssetObject}
            resizeMode={'contain'}
          />
        </DuoTone>
        <Image
          style={[styles.imageRocket, styles.imageRocket, rocketAssetObject.type !== 'default' ? styles.rocket2 : styles.rocket]}
          source={rocketAssetObject.image}
          resizeMode={'contain'}
        />
        <Image
          style={[styles.imageRocket, styles.layerRocket, turbineAssetObject.flames == 2 ? styles.turbine_out : styles.turbine]}
          source={turbineAssetObject.image}
          resizeMode={'contain'}
        />

        {turbineAssetObject.flames == 1 ?
          <ImageBackground
            source={require('../../assets/images/improvement_turbines/turbines_rocket/empty_space.png')}
            style={[styles.imageRocket, styles.layerRocket, styles.emptySpace]}>
            <Image source={typeFlame(Math.round(78 ?? 0)) /*require('../../../assets/images/cores/Truster_High_looped.gif') { uri: 'https://acegif.com/wp-content/gifs/fire-84.gif' }*/}
              resizeMode={'contain'}
              style={styles.fullAnimation} />
            {/* <LottieView
              style={styles.fullAnimation}
              source={flameAnimation}
              autoPlay={true}
              loop={true}
            /> */}
          </ImageBackground>
          :
          null}

        {turbineAssetObject.flames == 2 ?
          <>
            <ImageBackground
              source={require('../../assets/images/improvement_turbines/turbines_rocket/empty_space.png')}
              style={[styles.imageRocket, styles.layerRocket, styles.emptySpace, styles.duoLeft]}>
              {/* <LottieView
                style={styles.smallAnimation}
                source={flameAnimation}
                autoPlay={true}
                loop={true}
              /> */}
              <Image source={typeFlame(Math.round(78 ?? 0)) /*require('../../../assets/images/cores/Truster_High_looped.gif') { uri: 'https://acegif.com/wp-content/gifs/fire-84.gif' }*/}
                resizeMode={'contain'}
                style={styles.smallAnimation} />
            </ImageBackground>
            <ImageBackground
              source={require('../../assets/images/improvement_turbines/turbines_rocket/empty_space.png')}
              style={[styles.imageRocket, styles.layerRocket, styles.emptySpace, styles.duoRight]}>
              <Image source={typeFlame(Math.round(78 ?? 0)) /*require('../../../assets/images/cores/Truster_High_looped.gif') { uri: 'https://acegif.com/wp-content/gifs/fire-84.gif' }*/}
                resizeMode={'contain'}
                style={[styles.smallAnimation, { marginLeft: 8 }]} />
              {/* <LottieView
                style={styles.smallAnimation}
                source={flameAnimation}
                autoPlay={true}
                loop={true}
              /> */}
            </ImageBackground>
          </>
          : null}

        {turbineAssetObject.flames == 3 ? <>
          <ImageBackground
            source={require('../../assets/images/improvement_turbines/turbines_rocket/empty_space.png')}
            style={[styles.imageRocket, styles.layerRocket, styles.emptySpace, styles.flame_principal]}>
            {/* <LottieView
              style={styles.fullAnimationPlus}
              source={flameAnimation}
              autoPlay={true}
              loop={true}
            /> */}
            <Image source={typeFlame(Math.round(78 ?? 0)) /*require('../../../assets/images/cores/Truster_High_looped.gif') { uri: 'https://acegif.com/wp-content/gifs/fire-84.gif' }*/}
              resizeMode={'contain'}
              style={[styles.fullAnimationPlus]} />
          </ImageBackground>
          <ImageBackground
            source={require('../../assets/images/improvement_turbines/turbines_rocket/empty_space.png')}
            style={[styles.imageRocket, styles.layerRocket, styles.emptySpace, styles.duoLeftComp]}>
            {/* <LottieView
              style={styles.fullAnimationPlus}
              source={flameAnimation}
              autoPlay={true}
              loop={true}
            /> */}
            <Image source={typeFlame(Math.round(78 ?? 0)) /*require('../../../assets/images/cores/Truster_High_looped.gif') { uri: 'https://acegif.com/wp-content/gifs/fire-84.gif' }*/}
              resizeMode={'contain'}
              style={[styles.fullAnimationPlus]} />
          </ImageBackground>
          <ImageBackground
            source={require('../../assets/images/improvement_turbines/turbines_rocket/empty_space.png')}
            style={[styles.imageRocket, styles.layerRocket, styles.emptySpace, styles.duoRightComp]}>
            {/* <LottieView
              style={styles.fullAnimationPlus}
              source={flameAnimation}
              autoPlay={true}
              loop={true}
            /> */}
            <Image source={typeFlame(Math.round(78 ?? 0)) /*require('../../../assets/images/cores/Truster_High_looped.gif') { uri: 'https://acegif.com/wp-content/gifs/fire-84.gif' }*/}
              resizeMode={'contain'}
              style={[styles.fullAnimationPlus]} />
          </ImageBackground>
        </>
          : null}


        {turbineAssetObject.flames == 5 ? <>
          <ImageBackground
            source={require('../../assets/images/improvement_turbines/turbines_rocket/empty_space.png')}
            style={[styles.imageRocket, styles.layerRocket, styles.emptySpace, styles.flame_principal]}>
            {/* <LottieView
              style={styles.fullAnimationPlus}
              source={flameAnimation}
              autoPlay={true}
              loop={true}
            /> */}
            <Image source={typeFlame(Math.round(78 ?? 0)) /*require('../../../assets/images/cores/Truster_High_looped.gif') { uri: 'https://acegif.com/wp-content/gifs/fire-84.gif' }*/}
              resizeMode={'contain'}
              style={[styles.fullAnimationPlus]} />
          </ImageBackground>
          <ImageBackground
            source={require('../../assets/images/improvement_turbines/turbines_rocket/empty_space.png')}
            style={[styles.imageRocket, styles.layerRocket, styles.emptySpace, styles.duoLeftComp]}>
            {/* <LottieView
              style={styles.fullAnimationPlus}
              source={flameAnimation}
              autoPlay={true}
              loop={true}
            /> */}
            <Image source={typeFlame(Math.round(78 ?? 0)) /*require('../../../assets/images/cores/Truster_High_looped.gif') { uri: 'https://acegif.com/wp-content/gifs/fire-84.gif' }*/}
              resizeMode={'contain'}
              style={[styles.fullAnimationPlus]} />
          </ImageBackground>
          <ImageBackground
            source={require('../../assets/images/improvement_turbines/turbines_rocket/empty_space.png')}
            style={[styles.imageRocket, styles.layerRocket, styles.emptySpace, styles.duoRightComp]}>
            {/* <LottieView
              style={styles.fullAnimationPlus}
              source={flameAnimation}
              autoPlay={true}
              loop={true}
            /> */}
            <Image source={typeFlame(Math.round(78 ?? 0)) /*require('../../../assets/images/cores/Truster_High_looped.gif') { uri: 'https://acegif.com/wp-content/gifs/fire-84.gif' }*/}
              resizeMode={'contain'}
              style={[styles.fullAnimationPlus]} />
          </ImageBackground>
          <ImageBackground
            source={require('../../assets/images/improvement_turbines/turbines_rocket/empty_space.png')}
            style={[styles.imageRocket, styles.layerRocket, styles.emptySpace, styles.duoLeftExtra]}>
            {/* <LottieView
              style={styles.fullAnimationPlus}
              source={flameAnimation}
              autoPlay={true}
              loop={true}
            /> */}
            <Image source={typeFlame(Math.round(78 ?? 0)) /*require('../../../assets/images/cores/Truster_High_looped.gif') { uri: 'https://acegif.com/wp-content/gifs/fire-84.gif' }*/}
              resizeMode={'contain'}
              style={[styles.fullAnimationPlus]} />
          </ImageBackground>
          <ImageBackground
            source={require('../../assets/images/improvement_turbines/turbines_rocket/empty_space.png')}
            style={[styles.imageRocket, styles.layerRocket, styles.emptySpace, styles.duoRightExtra]}>
            {/* <LottieView
              style={styles.fullAnimationPlus}
              source={flameAnimation}
              autoPlay={true}
              loop={true}
            /> */}
            <Image source={typeFlame(Math.round(78 ?? 0)) /*require('../../../assets/images/cores/Truster_High_looped.gif') { uri: 'https://acegif.com/wp-content/gifs/fire-84.gif' }*/}
              resizeMode={'contain'}
              style={[styles.fullAnimationPlus]} />
          </ImageBackground>
        </>
          : null}


      </View>
    </>
  )
}
