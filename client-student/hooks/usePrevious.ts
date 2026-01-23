import { useEffect, useRef } from 'react';

/**
 * Hook pentru a obține valoarea anterioară a unei variabile
 */
export function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T | undefined>(undefined);
  useEffect(() => {
    ref.current = value;
  }, [value]);
  return ref.current;
}
