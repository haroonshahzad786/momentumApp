import React from 'react'
import { Image, Text, TouchableOpacity, View } from 'react-native'

import props from './props'
import styles from './styles'

export default ({
  category,
  textTitleStyle,
  backgroundColor,
  onPress,
  openMantra
}: props) => {
  const { name, enabled, mantra } = category

  const handleMantra = () => {
    if (enabled && mantra) openMantra(true)
    else null
  }

  return (
    <>
      <TouchableOpacity
        style={[styles.container, { backgroundColor }]}
        activeOpacity={enabled ? 0.4 : 1}
        onPress={/**onPress*/  enabled && !mantra ? onPress : () => handleMantra()}>
        <View style={styles.containerTextTitle}>
          <Text style={[styles.textTitle, textTitleStyle]} numberOfLines={1}>
            {name}
          </Text>
        </View>
        {enabled ? (
          <View style={styles.containerImageArrow}>
            <Image
              style={styles.imageArrow}
              source={require('../../assets/images/cockpit_categories/arrow.png')}
            />
          </View>
        ) : (
          <View style={styles.containerImageLock}>
            <Image
              style={styles.imageLock}
              source={require('../../assets/images/cockpit_categories/lock.png')}
            />
          </View>
        )}
      </TouchableOpacity>
    </>
  )
}
