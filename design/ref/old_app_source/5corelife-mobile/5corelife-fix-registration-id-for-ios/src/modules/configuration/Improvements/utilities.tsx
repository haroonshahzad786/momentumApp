import { fetchAxiosNoCache } from "../../../helpers/axios";
import { logger } from "../../../helpers/logger";
import { Improvement, ImprovementsUser } from "../../../typescript/main";

export const updateImprovementsState = (equip: ImprovementsUser[]): Improvement[] => {
    const types: Improvement['type'][] = ['ARMOR', 'THRUSTER', 'WINGS'];
  
    // Determine the improvements to use (equipped or default) for each type.
    const improvements = types.map(type => {
      const equipped = equip.find(item => item.improvement.improvement_type === type && item.equipped);
      const defaultItem = equip.find(item => item.improvement.improvement_type === type && item.improvement.default);
      
      logger.debug("Improvements.utilities equipped: ", equipped, "\ndefaultItem: ", defaultItem)
      const itemToUse = equipped || defaultItem;
      
      return itemToUse ? {
        cost: itemToUse.improvement.cost,
        id: itemToUse.improvement.order,
        isActive: itemToUse.equipped || itemToUse.improvement.default,
        name: itemToUse.improvement.name,
        type: itemToUse.improvement.improvement_type,
      } : null;
    }).filter(item => item !== null) as Improvement[];
  
    return improvements;
  };