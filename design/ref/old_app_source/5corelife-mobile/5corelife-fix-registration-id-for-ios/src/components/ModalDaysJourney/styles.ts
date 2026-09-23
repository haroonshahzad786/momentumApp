import { StyleSheet } from 'react-native'
import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({
    endlessJourney: {
        position: 'absolute',
        top: 41 + '%',
        right: 12 + '%',
        alignSelf: 'flex-end',
    },

    containerImgEndless: {
        height: vh(16.8)
    },

    textEndless: {
        position: 'absolute',
        width: 100 + '%',
        height: '100%',
        paddingTop: vh(2),
        paddingLeft: vw(2),
    }
})