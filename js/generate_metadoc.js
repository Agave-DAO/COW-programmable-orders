import { MetadataApi } from '@cowprotocol/app-data'

export const metadataApi = new MetadataApi()

const appCode = 'YOUR_APP_CODE'

const CoWHook = { callData : '0x...', target: '0x73280CC830A4BE3f14Ab2439660361dC70D024fd', gasLimit: '500000' }

const appDataDoc = await metadataApi.generateAppDataDoc({
    appDataParams: { appCode },
		PostHooks: [ CoWHook ],
})

console.log(appDataDoc)

console.log(await metadataApi.validateAppDataDoc({appDataDoc}))