import { describe, expect, it } from 'vitest'
import { reminderOptions } from './reminders'

describe('meeting reminder options',()=>{
  it('matches the mobile reminder choices',()=>expect(Object.keys(reminderOptions).map(Number)).toEqual([30,60,120,1440,2880,10080]))
})
