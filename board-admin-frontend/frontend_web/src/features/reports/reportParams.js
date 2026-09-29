export const pagedReportParams = ({ page = 0, size = 10, username = '' } = {}) => ({ page, size, ...(username.trim() ? { username: username.trim() } : {}) })

export const meetingHistoryParams = ({ categoryId = '', subcategoryId = '', from = '', to = '' } = {}) => ({
  ...(categoryId ? { categoryId } : {}),
  ...(subcategoryId ? { subcategoryId } : {}),
  ...(from ? { from } : {}),
  ...(to ? { to } : {}),
})
