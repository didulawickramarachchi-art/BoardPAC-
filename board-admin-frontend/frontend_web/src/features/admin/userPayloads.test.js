import { describe,expect,it } from 'vitest'
import { accessProfilesForRole,prepareUserPayload } from './userPayloads'

describe('user request payloads',()=>{
  it('uses backend enum names for secretary profiles',()=>expect(accessProfilesForRole('SECRETARY')).toContain('BOARD_SECRETARY'))
  it('trims strings without changing enum separators',()=>expect(prepareUserPayload({username:' didula ',accessProfile:'BOARD_SECRETARY'})).toEqual({username:'didula',accessProfile:'BOARD_SECRETARY'}))
})
