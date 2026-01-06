import ForwardedIconComponent from "@/components/common/genericIconComponent";

export default function LogoIcon() {
  return (
    <div className="relative flex h-8 w-8 items-center justify-center rounded-md bg-muted">
      <div className="flex h-8 w-8 items-center justify-center">
        <ForwardedIconComponent
          name="Bot"
          className="absolute h-[18px] w-[18px]"
        />
      </div>
    </div>
  );
}
