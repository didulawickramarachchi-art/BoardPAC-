export const accessProfilesByRole={
  ADMIN:['BOARD_ADMINISTRATOR','SYSTEM_ADMINISTRATOR'],
  SECRETARY:['BOARD_SECRETARY','SECRETARY_ASSISTANT','SECRETARY_UPLOAD_ONLY'],
  MEMBER:['MEMBER','MEMBER_VIEW_ONLY','MEMBER_VIEW_COMMENTS'],
}

export const accessProfilesForRole=role=>accessProfilesByRole[role]||Object.values(accessProfilesByRole).flat()

export const prepareUserPayload=form=>Object.fromEntries(Object.entries(form).map(([key,value])=>[key,typeof value==='string'?value.trim():value]))
