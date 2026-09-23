import React from 'react'
import { View } from 'react-native'
import { vh } from '../../helpers/dimensions'
import ButtonBack from '../ButtonBack'
import ButtonHelp from '../ButtonHelp'
import props from './props'
import styles from './styles'

export default ({
  dotsCount,
  activeDotIndex,
  activeDotStyle,
  dotStyle,
  onBackButton,
  onHelpButton,
  goHome,
  disabled,
}: props) => {
  let dots = [];

  const ActiveDot = (
    <View
      style={[
        {
          backgroundColor: '#f2faff',
          width: 8,
          height: 8,
          borderRadius: 4,
          marginLeft: 3,
          marginRight: 3,
          marginTop: 3,
          marginBottom: 3
        },
        activeDotStyle,
        styles.dot
      ]}
    />
  )
  const Dot = (
    <View
      style={[
        {
          backgroundColor: "#555555",
          width: 8,
          height: 8,
          borderRadius: 4,
          marginLeft: 3,
          marginRight: 3,
          marginTop: 3,
          marginBottom: 3
        },
        dotStyle,
        styles.dot
      ]}
    />
  )

  for (let i = 0; i < dotsCount; i++) {
    dots.push(
      i === activeDotIndex
        ? React.cloneElement(ActiveDot, { key: i })
        : React.cloneElement(Dot, { key: i })
    )
  }

  return (
    <>
      <View style={styles.headerDotsContainer}>
        <View style={styles.backButton}>
          {onBackButton && (
            <ButtonBack
              disabled={disabled}
              onPress={() => { onBackButton() }}
            />
          )}
        </View>

        {
          goHome
            ?
            <View style={styles.backButtonHome}>
              <ButtonBack
                disabled={disabled}
                onPress={() => goHome()}
                stylesCustomer={styles.stylesCustomer}
              />
              <View style={styles.dotsContainer}>
                {dots}
              </View>
            </View>
            :
            <View style={styles.dotsContainerWithout}>
              {dots}
            </View>
        }

        <View style={styles.helpButton}>
          {onHelpButton && (
            <ButtonHelp
              disabled={disabled}
              onPress={
                () => { onHelpButton('Help') }
              } />
          )}
        </View>
      </View>
    </>
  )
}
