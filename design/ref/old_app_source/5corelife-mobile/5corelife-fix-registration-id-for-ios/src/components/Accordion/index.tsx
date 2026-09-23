import React, { useState } from 'react'
import { Image, LayoutAnimation, Text, TouchableOpacity, View } from 'react-native'
import { useRecoilValue } from 'recoil'
import { storageAtom } from '../../recoil/atoms'
import props from './props'
import styles from './styles'

export default ({
  data, questions
}: props) => {

  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)

  const [expandedIndex, setExpanded] = useState(-1);

  const toggleExpand = (key: number) => {
    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
    setExpanded(key === expandedIndex ? -1 : key);
  }

  const getDateString = (dateString: string) => {
    var date = new Date(dateString);

    const monthName = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"][date.getMonth()];
    const d = date.getDate();

    let nth = "";
    if (d > 3 && d < 21) nth = 'th';
    switch (d % 10) {
      case 1: nth = "st";
      case 2: nth = "nd";
      case 3: nth = "rd";
      default: nth = "th";
    }

    return `${monthName} ${d}${nth}`
  }

  return <>{data.map((item, key) => (
    <View style={styles.container}>
      <TouchableOpacity style={styles.row} onPress={() => toggleExpand(key)}>
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
          {getDateString(item.date)}
        </Text>
        <Image
          source={expandedIndex === key ? require('../../assets/images/shared/arrow_up.png') : require('../../assets/images/shared/arrow_down.png')}
          resizeMode={'contain'}
        />
      </TouchableOpacity>

      {expandedIndex !== key ? <View style={styles.parentHr} /> : null}
      {
        expandedIndex === key &&
        <View style={styles.child}>
          {item.answers.map((sub) => (
            <View>
              <Text
                style={[
                  styles.textSubtitle,
                  [
                    fonts.ACCORDION_SUBTITLE,
                    {
                      color: palette.TEXT_PRIMARY
                    }
                  ]
                ]}>{questions[sub.question_number]}</Text>
              <Image
                style={styles.imageLine}
                source={require('../../assets/images/shared/line-left-dot.png')}
                resizeMode={'contain'}
              />
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
                ]}>{sub.answer}</Text>
            </View>
          ))}
          <View style={styles.parentHr} />
        </View>
      }
    </View>
  ))}
  </>
}