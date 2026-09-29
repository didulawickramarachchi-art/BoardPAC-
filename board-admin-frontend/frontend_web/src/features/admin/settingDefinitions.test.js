import { describe, expect, it } from 'vitest'
import { settingDefinitions } from './settingDefinitions'

describe('mobile setting parity catalog',()=>{
  it('includes every mobile settings group',()=>expect(Object.keys(settingDefinitions)).toEqual(['MEETING_CIRCULAR','AGENDA','PAPER','USER_MANAGEMENT','COMMENT','GENERAL']))
  it('preserves dependent and multi-select controls',()=>{
    expect(settingDefinitions.PAPER.find(item=>item.key==='annotation_tools').control).toBe('multi')
    expect(settingDefinitions.USER_MANAGEMENT.find(item=>item.key==='verification_code_expiry').enabledBy).toBe('two_step_authentication')
  })
})
