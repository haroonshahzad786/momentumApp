import { StyleSheet } from 'react-native'
import { vh, vw } from '../../helpers/dimensions'

export default StyleSheet.create({

    container: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
    },

    arrowSelecting: {
        width: vh(2),
        height: vh(2),
    },

    arrowThree: {
        opacity: 0.6,
    },
})