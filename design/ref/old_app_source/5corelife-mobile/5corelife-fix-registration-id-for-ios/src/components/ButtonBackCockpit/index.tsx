import React from 'react'
import { TouchableOpacity, View, Image } from 'react-native'
import props from './props'
import styles from './styles'

export default function index({ onPress, disabled }: props) {
    return (
        <TouchableOpacity disabled={disabled} style={styles.container} onPress={onPress}>
            <Image
                style={[styles.arrowSelecting, styles.arrowThree]}
                source={require('../../assets/images/onboarding/iconSelection.png')}
                resizeMode={'contain'}
            />
        </TouchableOpacity>
    )
}
