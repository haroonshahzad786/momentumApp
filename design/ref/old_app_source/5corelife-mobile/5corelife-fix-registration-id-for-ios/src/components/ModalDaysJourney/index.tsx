import React from 'react'
import { View, Text, Image } from 'react-native'
import string from './strings'
import styles from './styles';
import props from './props'
import { vw } from '../../helpers/dimensions';

export default function index({
    colorTextPrimary,
    colorTextSecundary,
    fontGlobal,
    daysJourney
}: props) {
    return (
        <View style={styles.endlessJourney}>
            <Image
                source={require('../../assets/images/journey/screen.png')}
                style={styles.containerImgEndless}
                resizeMode={'contain'}
            />
                <View style={styles.textEndless}>
                    <Text
                        numberOfLines={1}
                        adjustsFontSizeToFit
                        style={[fontGlobal, { fontSize: vw(6), color: colorTextPrimary, textAlign: 'center' }]}>
                        {string.STREAK}
                    </Text>
                    <Text
                        numberOfLines={1}
                        adjustsFontSizeToFit
                        style={[fontGlobal, { fontSize: vw(10), color: colorTextSecundary, textAlign: 'center' }]}>
                        {daysJourney}
                    </Text>
                    <Text
                        numberOfLines={1}
                        adjustsFontSizeToFit
                        style={[fontGlobal, { fontSize: vw(3), color: colorTextSecundary, textAlign: 'center' }]}>
                        {string.DAYS}
                    </Text>
                    <Text
                        numberOfLines={1}
                        adjustsFontSizeToFit
                        style={[fontGlobal, { fontSize: vw(3), color: colorTextSecundary, textAlign: 'center' }]}>
                        {string.IN_A_ROW}
                    </Text>
                </View>
        </View>
    )
}