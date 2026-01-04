import { Colors } from '../constants/theme';
import { useColorScheme } from './use-color-scheme';

export function useThemeColor(
  props: { light?: string; dark?: string },
  colorName: keyof typeof Colors.light & keyof typeof Colors.dark
) {
  const theme = useColorScheme() ?? 'light';

  if (theme === 'dark') {
    return props.dark ?? Colors.dark[colorName];
  }

  return props.light ?? Colors.light[colorName];
}
