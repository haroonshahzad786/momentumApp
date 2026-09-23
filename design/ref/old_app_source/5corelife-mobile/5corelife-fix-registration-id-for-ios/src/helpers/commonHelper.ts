import { useRecoilValue } from "recoil";
import { coresAtom, localDataAtom } from "../recoil/atoms";
import { CoreInfo } from "../typescript/main";

export const getNextPrev = (core_name: string, navigate: Function) => {
  const localData = useRecoilValue(localDataAtom).value;
  const coresInfo = localData.coreInfo ?? [];
  const coresLocal = useRecoilValue(coresAtom).value ?? [];

  const orderedCores = [
    // Order to show in dashboard
    coresInfo[1], // Mindset 0
    coresInfo[4], // Emotional 1
    coresInfo[3], // Relationships 2
    coresInfo[0], // Physical 3
    coresInfo[2], // Carrer 4
  ];

  const coreIndex = orderedCores.findIndex(x => x.core_string === core_name);
  const prevIndex = coreIndex < 1 ? orderedCores.length - 1 : coreIndex - 1;
  const nextIndex = coreIndex > 3 ? 0 : coreIndex + 1;

  const returnReditect = (item: CoreInfo) => {
    let dbCore = coresLocal.find(x => x.core_string == item.core_string);
    item = { ...item, enabled: dbCore?.enabled === true || coresInfo.find(x => x.core_string === item.core_string)?.enabled === true }
    // const onPressAction = () => {
    if (item.enabled === true)
      return navigate('CoreStackScreen', {
        screen: 'CheckHabits',
        params: {
          core: item,
          habits: item.morningCheckInHabits, // Habitos cargados del morning.
          score: item.nightCheckInScore,
        },
      });
    else
      return navigate('CoreStackScreen', {
        screen: 'InitHabits',
        params: {
          core: item,
        },
      });
  };

  return ({
    prevCore: () => { returnReditect(orderedCores[prevIndex]) },
    nextCore: () => { returnReditect(orderedCores[nextIndex]) }
  })
}
