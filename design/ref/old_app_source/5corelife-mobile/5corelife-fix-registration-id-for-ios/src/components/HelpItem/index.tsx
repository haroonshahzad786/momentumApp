import React,{useEffect, useState}  from 'react'
import { useRecoilValue } from 'recoil'
import { storageAtom } from '../../recoil/atoms'
import {
  Image,
  SafeAreaView,
  LayoutAnimation,
  StyleSheet,
  View,
  Text,
  ScrollView,
  UIManager,
  TouchableOpacity,
  Platform,
}  from 'react-native'

import props from './props'
import styles from './styles'

export default ({item}:props) => {
  const [expanded,setExpanded] = useState(false);
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)

  const toggleExpand = () => {
    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
    setExpanded(!expanded);
  }

  return (
    <View style={styles.container}>
      <TouchableOpacity style={styles.row} onPress={() => toggleExpand()}>
        <Text
          style={[
            styles.textTitle,
            [
              fonts.ACCORDION_TITLE,
              {
                color: palette.TEXT_TERTIARY,
                textShadowColor: palette.TEXT_PRIMARY_SHADOW
              }
            ]
          ]}>
          {item.title}
        </Text>
        <Image
          source={expanded ? require('../../assets/images/shared/arrow_up.png') : require('../../assets/images/shared/arrow_down.png')}
          resizeMode={'contain'}
        />
      </TouchableOpacity>

      {expanded ? <View style={styles.parentHr} /> : null}
      {
       expanded &&
        <View style={styles.child}>
          {item.content.map((paragraph,i,arr) => (
            <View>
              <Text
                //line-left-dot
                style={[
                  styles.textDescription,
                  [
                    fonts.ACCORDION_DESCRIPTION,
                    {
                      color: palette.TEXT_PRIMARY
                    }
                  ]
                ]}>{paragraph.text}</Text>
                {i !== (arr.length-1) ? 
                  <Text style={[
                    styles.textSeparator,
                    [
                      fonts.ACCORDION_DESCRIPTION,
                      {
                        color: palette.TEXT_PRIMARY
                      }
                    ]
                  ]}>---</Text>:null
                }
            </View>
          ))}
          <View style={styles.parentHr} />
        </View>
      }
    </View>
  );
}
