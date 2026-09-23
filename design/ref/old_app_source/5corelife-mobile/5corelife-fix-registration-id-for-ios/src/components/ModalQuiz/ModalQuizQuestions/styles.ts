import { StyleSheet } from 'react-native'

import { vh, vw } from '../../../helpers/dimensions'

export default StyleSheet.create({
  questionRow: {
    flexGrow: 1,
    flexDirection: 'row',
    alignItems: 'stretch',
    flexShrink: 0,
    flexBasis: 0,
  },
  questionTickContainer: {
    height: '100%',
    flexBasis: '25%',
    alignItems: 'stretch',
    padding: '4%',
  },
  questionTick: {
    width: '100%',
    flexGrow: 1,
  },
  questionTextContainer: {
    textAlignVertical: 'center',
    flexBasis: '75%',
  },
  quizScoreTextContainer: {
    textAlignVertical: 'center',
    marginTop: vh(1.5),
  },
  questionTickCharacter: {
    position: 'absolute',
    top: vh(2.8),
    left: vw(7.2),
  },
  textAnswer: {
    textAlign: 'justify',
    fontWeight: '500'
  }
})
