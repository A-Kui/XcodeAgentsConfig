import Testing
@testable import XcodeAgentsConfig

struct XcodeAgentConfiguratorTests {
    @Test
    func removesLegacyAndCurrentManagedBlocks() {
        let contents = """
        # BEGIN XcodeAgentsConfig managed codex override
        model_provider = "old"
        # END XcodeAgentsConfig managed codex override

        keep = "me"

        # BEGIN kXcodeAgentsConfig managed codex override
        model_provider = "new"
        # END kXcodeAgentsConfig managed codex override
        """

        let cleaned = XcodeAgentConfigurator.removingManagedCodexBlocks(from: contents)

        #expect(cleaned == #"keep = "me""#)
    }
}
