import { act, renderHook, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('@/lib/settings-storage', async (importOriginal) => {
  const actual = await importOriginal<typeof import('@/lib/settings-storage')>();
  return {
    ...actual,
    hasAnyApiKey: vi.fn(),
  };
});

import { hasAnyApiKey } from '@/lib/settings-storage';
import { useAgentChat } from '../useAgentChat';

const mockedHasAnyApiKey = vi.mocked(hasAnyApiKey);

describe('useAgentChat', () => {
  beforeEach(() => {
    localStorage.clear();
    mockedHasAnyApiKey.mockReset();
    mockedHasAnyApiKey.mockReturnValue(false);
  });

  it('refreshes hasApiKey after the registry update event', async () => {
    const { result } = renderHook(() => useAgentChat());

    await waitFor(() => expect(result.current.ready).toBe(true));
    expect(result.current.hasApiKey).toBe(false);

    mockedHasAnyApiKey.mockReturnValue(true);
    act(() => {
      window.dispatchEvent(new Event('nova-model-registry-updated'));
    });

    expect(result.current.hasApiKey).toBe(true);
  });
});
