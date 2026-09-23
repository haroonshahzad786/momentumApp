import { RFValue } from 'react-native-responsive-fontsize'

import fonts from '../themes/fonts.json'

// TODO: resizear de manera diferente las familias

Object.keys(fonts).forEach((fontsResizedName) => {
  // @ts-ignore: TypeScript pains.
  Object.keys(fonts[fontsResizedName]).forEach((fontsResizedProperty) => {
    if (fontsResizedProperty === 'fontSize') {
      // @ts-ignore: TypeScript pains.
      fonts[fontsResizedName][fontsResizedProperty] = RFValue(
        // @ts-ignore: TypeScript pains.
        fonts[fontsResizedName][fontsResizedProperty] * 1.3
      )
    }
  })
})

export default fonts
