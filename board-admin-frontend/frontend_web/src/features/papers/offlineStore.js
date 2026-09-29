const DB_NAME = 'boardpac-offline'
const STORE = 'papers'

const openDb = () => new Promise((resolve, reject) => {
  const request = indexedDB.open(DB_NAME, 1)
  request.onupgradeneeded = () => request.result.createObjectStore(STORE, { keyPath: 'paperId' })
  request.onsuccess = () => resolve(request.result)
  request.onerror = () => reject(request.error)
})

const transact = async (mode, action) => {
  const db = await openDb()
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(STORE, mode)
    const request = action(transaction.objectStore(STORE))
    request.onsuccess = () => resolve(request.result)
    request.onerror = () => reject(request.error)
    transaction.oncomplete = () => db.close()
  })
}

export const getOfflinePaper = paperId => transact('readonly', store => store.get(Number(paperId)))
export const saveOfflinePaper = record => transact('readwrite', store => store.put({ ...record, paperId: Number(record.paperId), savedAt: new Date().toISOString() }))
export const removeOfflinePaper = paperId => transact('readwrite', store => store.delete(Number(paperId)))
